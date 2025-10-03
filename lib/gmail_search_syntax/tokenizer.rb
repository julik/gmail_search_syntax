module GmailSearchSyntax
  class Token
    attr_reader :type, :value, :position

    def initialize(type, value, position)
      @type = type
      @value = value
      @position = position
    end

    def ==(other)
      other.is_a?(Token) && @type == other.type && @value == other.value
    end

    def inspect
      "#<Token #{@type} #{@value.inspect}>"
    end
  end

  class Tokenizer
    OPERATORS = %w[
      from to cc bcc subject after before older newer older_than newer_than
      label category has list filename in is deliveredto size larger smaller
      rfc822msgid
    ].freeze

    LOGICAL_OPERATORS = %w[OR AND AROUND].freeze

    def initialize(input)
      @input = input
      @position = 0
      @tokens = []
    end

    def tokenize
      while @position < @input.length
        skip_whitespace

        break if @position >= @input.length

        char = current_char

        case char
        when "("
          add_token(:lparen, char)
          advance
        when ")"
          add_token(:rparen, char)
          advance
        when "{"
          add_token(:lbrace, char)
          advance
        when "}"
          add_token(:rbrace, char)
          advance
        when "-"
          next_char = peek_char
          if next_char && next_char !~ /\s/
            add_token(:minus, char)
            advance
          else
            read_word
          end
        when "+"
          add_token(:plus, char)
          advance
        when '"'
          read_quoted_string
        when ":"
          add_token(:colon, char)
          advance
        else
          read_word
        end
      end

      add_token(:eof, nil)
      @tokens
    end

    private

    def current_char
      @input[@position]
    end

    def peek_char(offset = 1)
      @input[@position + offset]
    end

    def advance
      @position += 1
    end

    def skip_whitespace
      while @position < @input.length && @input[@position] =~ /\s/
        advance
      end
    end

    def add_token(type, value)
      @tokens << Token.new(type, value, @position)
    end

    def read_quoted_string
      advance

      value = ""
      while @position < @input.length && current_char != '"'
        if current_char == "\\"
          advance
          value += current_char if @position < @input.length
        else
          value += current_char
        end
        advance
      end

      advance if @position < @input.length

      add_token(:quoted_string, value)
    end

    def read_word
      value = ""

      while @position < @input.length
        char = current_char
        break if /[\s():{}]/.match?(char)
        break if char == "-"
        value += char
        advance
      end

      return if value.empty?

      if LOGICAL_OPERATORS.include?(value)
        add_token(value.downcase.to_sym, value)
      elsif /@/.match?(value)
        add_token(:email, value)
      elsif /^\d+$/.match?(value)
        add_token(:number, value.to_i)
      elsif value =~ /^\d{4}\/\d{2}\/\d{2}$/ || value =~ /^\d{2}\/\d{2}\/\d{4}$/
        add_token(:date, value)
      elsif /^(\d+)([dmy])$/.match?(value)
        add_token(:relative_time, value)
      else
        add_token(:word, value)
      end
    end
  end
end
