module GmailSearchSyntax
  module AST
    class Node
      def ==(other)
        self.class == other.class && attributes == other.attributes
      end

      def attributes
        instance_variables.map { |var| instance_variable_get(var) }
      end

      def short_class_name
        self.class.name.split("::").last
      end
    end

    class Operator < Node
      attr_reader :name, :value

      def initialize(name, value)
        @name = name
        @value = value
      end

      def inspect
        "#<#{short_class_name} #{@name}: #{@value.inspect}>"
      end
    end

    class LooseWord < Node
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def inspect
        "#<#{short_class_name} #{@value.inspect}>"
      end
    end

    class ExactWord < Node
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def inspect
        "#<#{short_class_name} #{@value.inspect}>"
      end
    end

    class And < Node
      attr_reader :operands

      def initialize(operands)
        @operands = operands
      end

      def inspect
        "#<#{short_class_name} #{@operands.map(&:inspect).join(" AND ")}>"
      end
    end

    class Or < Node
      attr_reader :operands

      def initialize(operands)
        @operands = operands
      end

      def inspect
        "#<#{short_class_name} #{@operands.map(&:inspect).join(" OR ")}>"
      end
    end

    class Not < Node
      attr_reader :child

      def initialize(child)
        @child = child
      end

      def inspect
        "#<#{short_class_name} #{@child.inspect}>"
      end
    end

    class Group < Node
      attr_reader :children

      def initialize(children = [])
        @children = children
      end

      def inspect
        "#<#{short_class_name} #{@children.inspect}>"
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
        "#<#{short_class_name} #{@left.inspect} AROUND #{@distance} #{@right.inspect}>"
      end
    end
  end
end
