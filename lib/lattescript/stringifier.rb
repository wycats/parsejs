module LatteScript
  class Visitor
    def accept(node)
      return "" if node.nil?

      out = if node.cuddly?
        " " << visit(node)
      elsif @newline
        @newline = false
        current_indent << visit(node)
      else
        visit(node)
      end

      out << newline if node.statement? && !@newline && !@skip_newline
      out
    end

    def visit(node)
      type = node.class.name.split("::").last
      send("visit_#{type}", node)
    end
  end

  class Stringifier < Visitor
    def self.to_string(ast)
      new(ast).to_string
    end

    def initialize(ast)
      @ast = ast
      @indent = 0
    end

    def indent
      @indent += 1
    end

    def outdent
      @indent -= 1
    end

    def current_indent
      "  " * @indent
    end

    def newline
      @newline = true
      "\n"
    end

    def cuddle(node, out, more=false)
      if node.cuddly?
        node.cuddle! if more
      else
        indent
        out << newline
      end

      out << accept(node)

      outdent unless node.cuddly?
    end

    def without_newline
      old, @skip_newline = @skip_newline, true
      yield
      @skip_newline = old
    end

    def to_string
      accept @ast
    end

    def visit_Program(program)
      program.elements.map { |element| accept(element) }.join(";")
    end

    def visit_ExpressionStatement(statement)
      accept(statement.expression) + ";"
    end

    def visit_SequenceExpression(expression)
      out = ""
      out << "(" if expression.parens
      out << expression.expressions.map { |expression| accept(expression) }.join(", ")
      out << ")" if expression.parens
      out
    end

    def visit_Identifier(id)
      id.name
    end

    def visit_Literal(literal)
      case val = literal.val
      when nil
        "null"
      when LatteScript::AST::Node
        accept val
      else
        val.inspect
      end
    end

    def visit_Number(number)
      number.val
    end

    def visit_String(string)
      string.val.inspect
    end

    def visit_UnaryExpression(unary)
      space = unary.op =~ /\w/ ? sp : ""
      unary.op + space + accept(unary.argument)
    end

    def visit_AssignmentExpression(expr)
      accept(expr.left) + sp + expr.op + sp + accept(expr.right)
    end

    def visit_CallExpression(expr)
      accept(expr.callee) + "(" + expr.args.map { |arg| accept(arg) }.join(", ") + ")"
    end

    def visit_ArrayExpression(expr)

      "[" + begin

        last, out = expr.elements.size - 1, ""
        expr.elements.each_with_index do |element, i|
          if element.nil?
            out << ","
            out << " " unless i == last
          else
            out << accept(element)
            out << ", " unless i == last
          end
        end
        out

      end + "]"
    end

    def visit_ObjectExpression(expr)
      "{" + expr.properties.map { |prop| accept(prop) }.join(", ") + "}"
    end

    def visit_Property(property)
      accept(property.key) + ": " + accept(property.value)
    end

    def visit_MemberExpression(expr)
      left = accept(expr.object)
      right = accept(expr.property)

      if expr.computed
        "#{left}[#{right}]"
      else
        "#{left}.#{right}"
      end
    end

    def visit_NewExpression(expr)
      left = "new " + accept(expr.callee)
      args = "(" + expr.args.map { |arg| accept(arg) }.join(", ") + ")" if args

      "#{left}#{args}"
    end

    def visit_BinaryExpression(expr)
      left = accept(expr.left)
      right = accept(expr.right)

      "#{left} #{expr.op} #{right}"
    end

    def visit_BlockStatement(statement)
      out = "{" << newline
      indent
      statement.statements.each { |statement| out << accept(statement) }
      outdent
      out << current_indent << "}"
      @newline = false unless statement.cuddly
      out
    end

    def visit_IfStatement(statement)
      consequent = statement.consequent
      alternate = statement.alternate

      out = "if (" + accept(statement.test) + ")"

      cuddle(consequent, out, true)

      if alternate
        out << " " if consequent.cuddly?
        out << current_indent << "else"
        cuddle(alternate, out, false)
      end

      out
    end

    def visit_WhileStatement(statement)
      test = statement.test
      body = statement.body

      out = "while (" + accept(test) + ")"
      cuddle(body, out, false)
      out
    end

    def visit_EmptyStatement(empty)
      ";"
    end

    def visit_ForStatement(statement)
      init = statement.init
      test = statement.test
      update = statement.update
      body = statement.body
      out = ""

      without_newline do
        out << "for (" + accept(init) + ";"
        test = accept(test)
        out << " #{test}" unless test.empty?
        out << ";"
        update = accept(update)
        out << " #{update}" unless update.empty?
        out << ")"
      end

      cuddle(body, out, false)
      out
    end

    def visit_VariableDeclaration(decl)
      decl.kind + " " + decl.declarations.map { |d| accept(d) }.join(", ")
    end

    def visit_VariableDeclarator(decl)
      out = accept(decl.id)
      out << " = " + accept(decl.init) if decl.init
      out
    end

    def visit_UpdateExpression(expr)
      op = expr.op
      prefix = expr.prefix

      op += " " if op =~ /\w/
      argument = accept(expr.argument)

      if prefix
        "#{op}#{argument}"
      else
        "#{argument}#{op}"
      end
    end

    def visit_ForInStatement(statement)
      left = statement.left
      right = statement.right
      body = statement.body

      out = ""

      without_newline do
        out << "for (" + accept(left) + " in " + accept(right) + ")"
      end

      cuddle(body, out, false)
      out
    end

  private
    def sp
      " "
    end
  end
end
