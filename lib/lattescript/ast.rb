module LatteScript
  module AST
    class Node
      def cuddly?
        false
      end

      def statement?
        false
      end

      def needs_newline?
        false
      end
    end

    class SequenceExpression
      attr_accessor :parens
    end

    class BlockStatement
      attr_accessor :cuddly

      def cuddle!
        @cuddly = true
      end

      def needs_newline?
        !@cuddly
      end

      def cuddly?
        true
      end

      def statement?
        true
      end
    end

    statements  = [VariableDeclaration, EmptyStatement, ExpressionStatement, IfStatement]
    statements += [WhileStatement, ForStatement, ForInStatement, DoWhileStatement]
    statements += [ContinueStatement, BreakStatement, ReturnStatement, WithStatement]
    statements += [LabeledStatement, SwitchStatement, ThrowStatement, TryStatement]
    statements += [DebuggerStatement, FunctionDeclaration]

    statements.each do |statement|
      statement.class_eval do
        def needs_newline?
          true
        end

        def statement?
          true
        end
      end
    end
  end
end

