require "json"

module LatteScript
  class Visitor
    def accept(node)
      return "" if node.nil?

      nl = @newline

      out = if node.cuddly?
        " " << visit(node)
      elsif @newline
        @newline = false
        current_indent << visit(node)
      else
        visit(node)
      end

      out << newline if node.needs_newline? && needs_newline?(out)

      out
    end

    def visit(node)
      type = node.class.name.split("::").last
      send("visit_#{type}", node)
    end
  end

  class Stringifier < Visitor
    def self.to_string(ast)
      stringifier = new(ast)
      yield stringifier if block_given?
      stringifier.to_string
    end

    attr_accessor :include_comments

    def initialize(ast)
      @ast = ast
      @indent = 0
      @include_comments = false
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

      if more && node.cuddly?
        out << " "
        @newline = false
      end

      unless node.cuddly?
        outdent
        out << current_indent if more
      end
    end

    def without_newline
      old, @skip_newline = @skip_newline, true
      ret = yield
      @skip_newline = old
      ret
    end

    def needs_newline?(out)
      out !~ /\n$/ && !@skip_newline
    end

    def strip_newline(str)
      @newline = false
      str.sub(/\n$/, '')
    end

    def to_string
      accept @ast
    end

    def visit_Program(program)
      program.elements.map { |element| accept(element) }.join("")
    end

    def visit_ExpressionStatement(statement)
      accept(statement.expression) + ";"
    end

    def visit_SequenceExpression(expression)
      out = ""
      out << "(" if expression.parens
      exprs = expression.expressions.map { |e| accept(e) }.join(", ")
      exprs = strip_newline(exprs) if expression.parens
      out << exprs
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
      string.quote + string.val + string.quote
    end

    def visit_UnaryExpression(unary)
      space = unary.op =~ /\w/ ? sp : ""
      unary.op + space + accept(unary.argument)
    end

    def visit_AssignmentExpression(expr)
      accept(expr.left) + sp + expr.op + sp + accept(expr.right)
    end

    def visit_CallExpression(expr)
      out = strip_newline(accept(expr.callee))
      args = expr.args.map { |arg| accept(arg) }.join(", ")
      args = strip_newline(args)
      out << "(" + args + ")"
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
      comments = property.comments.map { |comment| accept(comment) }.join("")
      comments + accept(property.key) + ": " + accept(property.value)
    end

    def visit_CommentedStatement(statement)
      out = ""

      if comments = statement.comments
        comments.each { |comment| out << accept(comment) }
      end

      out << accept(statement.statement)
    end

    def visit_MemberExpression(expr)
      left = strip_newline(accept(expr.object))
      right = accept(expr.property)

      if expr.computed
        "#{left}[#{right}]"
      else
        "#{left}.#{right}"
      end
    end

    def visit_NewExpression(expr)
      args = expr.args
      left = "new " + accept(expr.callee)
      arg_string = "(" + args.map { |arg| accept(arg) }.join(", ") + ")" if args

      "#{left}#{arg_string}"
    end

    def visit_BinaryExpression(expr)
      left = strip_newline(accept(expr.left))
      right = accept(expr.right)

      "#{left} #{expr.op} #{right}"
    end

    alias visit_LogicalExpression visit_BinaryExpression

    def visit_BlockStatement(statement)
      out = "{" << newline
      indent
      statement.statements.each { |s| out << accept(s) }
      outdent
      out << current_indent << "}"
      @newline = false unless statement.cuddly
      out
    end

    def visit_IfStatement(statement)
      consequent = statement.consequent
      alternate = statement.alternate

      out = "if (" + accept(statement.test) + ")"

      cuddle(consequent, out, alternate)

      if alternate
        out << "else"
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

    def visit_DoWhileStatement(statement)
      out = "do"
      cuddle(statement.body, out, true)
      out << "while (" + accept(statement.test) + ");"
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
      out = decl.kind + " " + decl.declarations.map { |d| accept(d) }.join(", ")
      out << ";" if decl.semicolon
      out
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

    def visit_SwitchStatement(statement)
      out = ""

      without_newline do
        out << "switch (" + accept(statement.discriminant) + ") {" << newline
        indent
      end

      statement.cases.each { |c| out << accept(c) }
      outdent
      out << current_indent << "}" << newline
    end

    def visit_SwitchCase(switch)
      if switch.test
        out = "case #{accept(switch.test)}:" << newline
      else
        out = "default:" << newline
      end

      indent
      switch.consequent.each { |statement| out << accept(statement) }
      outdent
      out
    end

    def visit_ThrowStatement(statement)
      "throw #{accept(statement.argument)};"
    end

    def visit_TryStatement(statement)
      handler = statement.handler
      finalizer = statement.finalizer

      out = "try"

      cuddle(statement.block, out, handler || finalizer)

      if handler
        out << "catch (" + accept(handler.param) + ")"
        cuddle(handler.body, out, finalizer)
      end

      if finalizer
        out << "finally"
        cuddle(finalizer, out, false)
      end

      out
    end

    def visit_FunctionDeclaration(decl)
      id = decl.id
      params = decl.params
      body = decl.body

      out = "function " + accept(id) + "("
      out << params.map { |param| accept(param) }.join(", ")
      out << ") {" << newline

      indent
      decl.body.each { |s| out << accept(s) }
      outdent
      out << current_indent << "}"
    end

    alias visit_FunctionExpression visit_FunctionDeclaration

    def visit_ReturnStatement(statement)
      "return " + accept(statement.argument) + ";"
    end

    def visit_BreakStatement(statement)
      out = "break"
      out << " " << accept(statement.label) if statement.label
      out << ";"
    end

    def visit_ContinueStatement(statement)
      out = "continue"
      out << " " << accept(statement.label) if statement.label
      out << ";"
    end

    def visit_ThisExpression(statement)
      "this"
    end

    def visit_ConditionalExpression(expr)
      out = strip_newline(accept(expr.test))
      out << " ? " << strip_newline(accept(expr.consequent))
      out << " : " << accept(expr.alternate)
    end

    def visit_DebuggerStatement(expr)
      "debugger;"
    end

    def visit_Comment(comment)
      return "" unless include_comments
      if comment.type == 'singleline'
        "//" + comment.body + newline
      else
        body = comment.body.split("\n")
        first = body.shift
        out = "/*" + first + newline + body.map { |s| "#{current_indent}#{s}" }.join(newline) + "*/"
        out << "\n" if comment.newline
        out
      end
    end

    def visit_RegExp(regex)
      "/#{regex.body}/#{regex.flags}"
    end

  private
    def sp
      " "
    end
  end
end
