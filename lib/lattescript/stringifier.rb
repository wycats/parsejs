module LatteScript
  class Visitor
    def accept(node)
      type = node.class.name.split("::").last
      send("visit_#{type}", node)
    end
  end

  class Stringifier < Visitor
    def self.to_string(ast)
      new(ast).to_string
    end

    def initialize(ast)
      p ast
      @ast = ast
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
      expression.expressions.map { |expression| accept(expression) }.join(";")
    end

    def visit_Identifier(id)
      id.name
    end

    def visit_Literal(literal)
      case val = literal.val
      when nil
        "null"
      when LatteScript::Parser::AST::Node
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

  private
    def sp
      " "
    end
  end
end
