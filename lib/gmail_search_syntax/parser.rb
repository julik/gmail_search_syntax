module GmailSearchSyntax
  class Parser
    OPERATORS = %w[
      from to cc bcc subject after before older newer older_than newer_than
      label category has list filename in is deliveredto size larger smaller
      rfc822msgid
    ].freeze

    def initialize(tokens)
      @tokens = tokens
      @position = 0
    end

    def parse!
      children = []

      until eof?
        node = parse_expression
        children << node if node
      end

      if children.empty?
        raise GmailSearchSyntax::EmptyQueryError, "Query cannot be empty"
      end

      children.first
    end

    private

    def current_token
      @tokens[@position]
    end

    def peek_token(offset = 1)
      @tokens[@position + offset]
    end

    def advance
      @position += 1
    end

    def eof?
      current_token.nil? || current_token.type == :eof
    end

    def parse_expression
      parse_or_expression
    end

    def parse_or_expression
      operands = [parse_and_expression]

      while current_token&.type == :or
        advance
        operands << parse_and_expression
      end

      (operands.length == 1) ? operands.first : AST::Or.new(operands)
    end

    def parse_and_expression
      operands = []

      first = parse_around_expression
      operands << first if first

      while current_token&.type == :and
        advance
        operand = parse_around_expression
        operands << operand if operand
      end

      while !eof? && current_token.type != :or && current_token.type != :rparen &&
          current_token.type != :rbrace && current_token.type != :and
        operand = parse_around_expression
        break unless operand
        operands << operand
      end

      return nil if operands.empty?
      (operands.length == 1) ? operands.first : AST::And.new(operands)
    end

    def parse_around_expression
      left = parse_unary_expression

      if current_token&.type == :around
        advance
        distance = 5

        if current_token&.type == :number
          distance = current_token.value
          advance
        end

        right = parse_unary_expression
        return AST::Around.new(left, distance, right)
      end

      left
    end

    def parse_unary_expression
      if current_token&.type == :minus
        advance
        child = parse_primary_expression
        return AST::Not.new(child)
      end

      if current_token&.type == :plus
        advance
        return parse_primary_expression
      end

      parse_primary_expression
    end

    def parse_primary_expression
      return nil if eof?

      case current_token.type
      when :lparen
        parse_parentheses
      when :lbrace
        parse_braces
      when :word
        parse_operator_or_text
      when :quoted_string
        value = current_token.value
        advance
        AST::ExactWord.new(value)
      when :email, :number, :date, :relative_time
        value = current_token.value
        advance
        AST::LooseWord.new(value)
      else
        advance
        nil
      end
    end

    def parse_parentheses
      advance

      children = []
      while !eof? && current_token.type != :rparen
        node = parse_expression
        children << node if node
        break if current_token.type == :rparen
      end

      advance if current_token&.type == :rparen

      (children.length == 1) ? children.first : AST::Group.new(children)
    end

    def parse_braces
      advance

      children = []
      while !eof? && current_token.type != :rbrace
        node = parse_unary_expression
        children << node if node
        break if current_token.type == :rbrace
      end

      advance if current_token&.type == :rbrace

      (children.length == 1) ? children.first : AST::Or.new(children)
    end

    def parse_operator_or_text
      word = current_token.value

      if OPERATORS.include?(word.downcase) && peek_token&.type == :colon
        operator_name = word.downcase
        advance
        advance

        value = parse_operator_value
        return AST::Operator.new(operator_name, value)
      end

      advance
      AST::LooseWord.new(word)
    end

    def parse_operator_value
      return nil if eof?

      case current_token.type
      when :lparen
        parse_parentheses
      when :lbrace
        parse_braces
      when :quoted_string
        value = current_token.value
        advance
        value
      when :word, :email, :number, :date, :relative_time
        # Take only a single token as the operator value.
        # Multi-word values must be explicitly quoted: from:"john smith"
        # This matches Gmail's actual search behavior where bare words
        # after an operator are treated as separate search terms.
        value = current_token.value
        advance
        value.is_a?(Integer) ? value : value.to_s
      end
    end
  end
end
