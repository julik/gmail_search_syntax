require "test_helper"

class TokenizerTest < Minitest::Test
  def tokenize(input)
    GmailSearchSyntax::Tokenizer.new(input).tokenize
  end

  def assert_token_stream(expected_tokens, actual_tokens)
    assert expected_tokens.length > 0
    assert_equal expected_tokens.length, actual_tokens.length, "Expected #{expected_tokens.length} tokens, got #{actual_tokens.length}"

    expected_tokens.each_with_index do |expected_token, index|
      actual_token = actual_tokens[index]
      expected_token.each do |property, expected_value|
        actual_value = actual_token.public_send(property)
        assert_equal expected_value, actual_value, "Token #{index} #{actual_token}: expected #{property} to be #{expected_value.inspect}, got #{actual_value.inspect}"
      end
    end
  end

  def test_tokenize_simple_from
    tokens = tokenize("from:amy@example.com")
    expected = [
      {type: :word, value: "from"},
      {type: :colon},
      {type: :email, value: "amy@example.com"},
      {type: :eof}
    ]
    assert_token_stream(expected, tokens)
  end

  def test_tokenize_quoted_string
    tokens = tokenize('"hello world"')
    expected = [
      {type: :quoted_string, value: "hello world"},
      {type: :eof}
    ]
    assert_token_stream(expected, tokens)
  end

  def test_tokenize_operators
    tokens = tokenize("from:amy@example.com OR to:bob@example.com")
    expected = [
      {type: :word, value: "from"},
      {type: :colon},
      {type: :email, value: "amy@example.com"},
      {type: :or},
      {type: :word, value: "to"},
      {type: :colon},
      {type: :email, value: "bob@example.com"},
      {type: :eof}
    ]
    assert_token_stream(expected, tokens)
  end

  def test_tokenize_parentheses
    tokens = tokenize("subject:(meeting call)")
    expected = [
      {type: :word, value: "subject"},
      {type: :colon},
      {type: :lparen},
      {type: :word, value: "meeting"},
      {type: :word, value: "call"},
      {type: :rparen},
      {type: :eof}
    ]
    assert_token_stream(expected, tokens)
  end

  def test_tokenize_braces
    tokens = tokenize("{from:a from:b}")
    expected = [
      {type: :lbrace},
      {type: :word, value: "from"},
      {type: :colon},
      {type: :word, value: "a"},
      {type: :word, value: "from"},
      {type: :colon},
      {type: :word, value: "b"},
      {type: :rbrace},
      {type: :eof}
    ]
    assert_token_stream(expected, tokens)
  end

  def test_tokenize_negation
    tokens = tokenize("dinner -movie")
    expected = [
      {type: :word, value: "dinner"},
      {type: :minus},
      {type: :word, value: "movie"},
      {type: :eof}
    ]
    assert_token_stream(expected, tokens)
  end

  def test_tokenize_around
    tokens = tokenize("holiday AROUND 10 vacation")
    expected = [
      {type: :word, value: "holiday"},
      {type: :around},
      {type: :number, value: 10},
      {type: :word, value: "vacation"},
      {type: :eof}
    ]
    assert_token_stream(expected, tokens)
  end

  def test_tokenize_date
    tokens = tokenize("after:2004/04/16")
    expected = [
      {type: :word, value: "after"},
      {type: :colon},
      {type: :date, value: "2004/04/16"},
      {type: :eof}
    ]
    assert_token_stream(expected, tokens)
  end

  def test_tokenize_relative_time
    tokens = tokenize("older_than:1y")
    expected = [
      {type: :word, value: "older_than"},
      {type: :colon},
      {type: :relative_time, value: "1y"},
      {type: :eof}
    ]
    assert_token_stream(expected, tokens)
  end

  def test_tokenize_number
    tokens = tokenize("size:1000000")
    expected = [
      {type: :word, value: "size"},
      {type: :colon},
      {type: :number, value: 1000000},
      {type: :eof}
    ]
    assert_token_stream(expected, tokens)
  end

  def test_tokenize_and_operator
    tokens = tokenize("from:amy@example.com AND to:bob@example.com")
    expected = [
      {type: :word, value: "from"},
      {type: :colon},
      {type: :email, value: "amy@example.com"},
      {type: :and, value: "AND"},
      {type: :word, value: "to"},
      {type: :colon},
      {type: :email, value: "bob@example.com"},
      {type: :eof}
    ]
    assert_token_stream(expected, tokens)
  end

  def test_tokenize_plus
    tokens = tokenize("+unicorn")
    expected = [
      {type: :plus},
      {type: :word, value: "unicorn"},
      {type: :eof}
    ]
    assert_token_stream(expected, tokens)
  end

  def test_tokenize_complex_query
    tokens = tokenize('from:boss@example.com subject:"urgent meeting" has:attachment')
    expected = [
      {type: :word, value: "from"},
      {type: :colon},
      {type: :email, value: "boss@example.com"},
      {type: :word, value: "subject"},
      {type: :colon},
      {type: :quoted_string, value: "urgent meeting"},
      {type: :word, value: "has"},
      {type: :colon},
      {type: :word, value: "attachment"},
      {type: :eof}
    ]
    assert_token_stream(expected, tokens)
  end

  def test_tokenize_email_with_plus
    tokens = tokenize("to:user+tag@example.com")
    expected = [
      {type: :word, value: "to"},
      {type: :colon},
      {type: :email, value: "user+tag@example.com"},
      {type: :eof}
    ]
    assert_token_stream(expected, tokens)
  end

  def test_tokenize_multiple_words
    tokens = tokenize("project report meeting")
    expected = [
      {type: :word, value: "project"},
      {type: :word, value: "report"},
      {type: :word, value: "meeting"},
      {type: :eof}
    ]
    assert_token_stream(expected, tokens)
  end

  def test_tokenize_quoted_string_with_escaped_quote
    tokens = tokenize('"She said \\"hello\\" to me"')
    expected = [
      {type: :quoted_string, value: 'She said "hello" to me'},
      {type: :eof}
    ]
    assert_token_stream(expected, tokens)
  end

  def test_tokenize_quoted_string_with_escaped_backslash
    tokens = tokenize('"path\\\\to\\\\file"')
    expected = [
      {type: :quoted_string, value: 'path\\to\\file'},
      {type: :eof}
    ]
    assert_token_stream(expected, tokens)
  end

  def test_tokenize_quoted_string_with_multiple_escapes
    tokens = tokenize('"test \\"nested\\" and \\\\ slash"')
    expected = [
      {type: :quoted_string, value: 'test "nested" and \\ slash'},
      {type: :eof}
    ]
    assert_token_stream(expected, tokens)
  end

  def test_tokenize_word_with_escaped_quote
    tokens = tokenize('meeting\\"room')
    expected = [
      {type: :word, value: 'meeting"room'},
      {type: :eof}
    ]
    assert_token_stream(expected, tokens)
  end

  def test_tokenize_word_with_escaped_backslash
    tokens = tokenize('path\\\\to')
    expected = [
      {type: :word, value: 'path\\to'},
      {type: :eof}
    ]
    assert_token_stream(expected, tokens)
  end

  def test_tokenize_multiple_words_with_escapes
    tokens = tokenize('meeting\\"room another\\\\word')
    expected = [
      {type: :word, value: 'meeting"room'},
      {type: :word, value: 'another\\word'},
      {type: :eof}
    ]
    assert_token_stream(expected, tokens)
  end

  def test_tokenize_operator_value_with_escaped_quote
    tokens = tokenize('subject:test\\"value')
    expected = [
      {type: :word, value: "subject"},
      {type: :colon},
      {type: :word, value: 'test"value'},
      {type: :eof}
    ]
    assert_token_stream(expected, tokens)
  end
end
