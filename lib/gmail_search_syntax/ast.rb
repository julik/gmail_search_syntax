module GmailSearchSyntax
  module AST
    class Node
      def ==(other)
        self.class == other.class && attributes == other.attributes
      end

      def attributes
        instance_variables.map { |var| instance_variable_get(var) }
      end
    end

    class Operator < Node
      attr_reader :name, :value

      def initialize(name, value)
        @name = name
        @value = value
      end

      def inspect
        "#<Operator #{@name}: #{@value.inspect}>"
      end
    end

    class Text < Node
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def inspect
        "#<Text #{@value.inspect}>"
      end
    end

    class And < Node
      attr_reader :operands

      def initialize(operands)
        @operands = operands
      end

      def inspect
        "#<And #{@operands.map(&:inspect).join(" AND ")}>"
      end
    end

    class Or < Node
      attr_reader :operands

      def initialize(operands)
        @operands = operands
      end

      def inspect
        "#<Or #{@operands.map(&:inspect).join(" OR ")}>"
      end
    end

    class Not < Node
      attr_reader :child

      def initialize(child)
        @child = child
      end

      def inspect
        "#<Not #{@child.inspect}>"
      end
    end

    class Group < Node
      attr_reader :children

      def initialize(children = [])
        @children = children
      end

      def inspect
        "#<Group #{@children.inspect}>"
      end
    end

    class Around < Node
      attr_reader :left, :distance, :right

      def initialize(left, distance, right)
        @left = left
        @distance = distance
        @right = right
      end

      def inspect
        "#<Around #{@left.inspect} AROUND #{@distance} #{@right.inspect}>"
      end
    end
  end
end
