require "lattescript/visitor"

module LatteScript
  class CommentScanner < Visitor
    include LatteScript::AST

    def initialize(*)
      @current_comment = nil
      super
    end

    def comment?
      return false unless @current_comment
      return false if @current_comment.empty?
      return @current_comment.any?(&:multiline?)
    end

    def stringify(node)
      Stringifier.to_string(Marshal.load(Marshal.dump(node)))
    end

    def visit_AssignmentExpression(expr)
      process_comment(expr)
      super
    end

    def visit_CommentedStatement(comment)
      @current_comment = comment.comments

      super
    end

    def visit_Property(property)
      @current_comment = property.comments
      process_comment(property)

      super
    end

    def process_comment(node)
      print_comment(node)
    end

    def print_comment(node)
      return unless comment?

      puts
      puts "-" * 10 + node.class.name + "-" * 10
      puts @current_comment.map { |c| next unless c.multiline?; c.body }.join("\n")
      puts "-" * (10 + node.class.name.size + 10)
      puts

      puts Stringifier.to_string(Marshal.load(Marshal.dump(node)))
      puts
    ensure
      @current_comment = nil
    end
  end

  class ExtractDocs < CommentScanner
    include AST

    def initialize(*)
      @current_variables = []
      @current_class = []
    end

    def visit_Program(program)
      with_variables(program, []) { super }
    end

    def visit_FunctionDeclaration(decl)
      with_variables(decl) { super }
    end

    def visit_FunctionExpression(expr)
      with_variables(expr) { super }
    end

    def with_variables(expr, params=expr.params.map(&:val))
      locals = FindVars.find_variables(expr)
      @current_variables.push(locals | params)
      yield
    ensure
      @current_variables.pop
    end

    def variable?(name)
      @current_variables.find do |list|
        list.include?(name)
      end
    end

    def member_left(expr)
      object = expr

      while object
        if object.is_a?(Identifier)
          return object.val
        elsif object.is_a?(ThisExpression)
          return "this"
        elsif object.respond_to?(:object)
          object = object.object
        else
          return nil
        end
      end
    end

    def visit_AssignmentExpression(expr)
      right = expr.right
      in_class = false

      if right.is_a?(CallExpression)
        callee = expr.right.callee
        if callee.is_a?(MemberExpression) && !callee.computed
          property = callee.property.val
          if property == "extend"
            if expr.left.is_a?(MemberExpression)
              left_id = member_left(expr.left)
              extends = stringify(expr.right.callee).sub(/\.extend$/, '')

              if variable?(left_id)
                puts "Found class: #{stringify(expr.left)} (extends #{extends}), but it was private"
              else
                klass = stringify(expr.left)
                @current_class.push [klass, extends]
                in_class = true

                puts "Found class: #{stringify(expr.left)} (extends #{extends})"

                puts
                puts stripped_comment
                puts "-" * 80
              end
            end
          end
        end
      end

      super

    ensure
      @current_class.pop if in_class
    end

    def current_class_name
      klass, parent = @current_class.last
      "#{klass} < #{parent}"
    end

    def visit_Property(property)
      return if @current_class.empty?

      @current_comment = property.comments
      return if stripped_comment.empty?

      case property.value
      when FunctionDeclaration, FunctionExpression
        puts "Found a method named #{property.key.val} in #{current_class_name}:"
      else
        puts "Found a property named #{property.key.val} in #{current_class_name}:"
      end

      puts
      puts stripped_comment
      puts "-" * 80

      super
    end

    def stripped_comment
      comments = @current_comment.map do |c|
        next unless c.multiline?
        c.body
      end

      string = comments.join("\n")
      string.gsub!(/^[ \t]*\*?[ \t]*/, "").strip
    end

    def process_comment(*)
    end
  end

  require "set"

  class FindVars < Visitor
    def self.find_variables(ast)
      ast = Marshal.load(Marshal.dump(ast))

      finder = new
      finder.accept(ast)
      finder.variables
    end

    attr_reader :variables

    def initialize(*)
      @variables = Set.new
      super
    end

    def visit_VariableDeclarator(expr)
      @variables << expr.id.val
    end

    def visit_FunctionDeclaration(*)
    end

    def visit_FunctionExpression(*)
    end
  end
end
