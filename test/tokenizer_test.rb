require "test_helper"

class TokenizerTest < Minitest::Test
  def tokenize(input)
    GmailSearchSyntax::Tokenizer.new(input).tokenize
  end

  def test_tokenize_simple_from
    tokens = tokenize("from:amy@example.com")
    assert_equal 4, tokens.length
    assert_equal :word, tokens[0].type
    assert_equal "from", tokens[0].value
    assert_equal :colon, tokens[1].type
    assert_equal :email, tokens[2].type
    assert_equal "amy@example.com", tokens[2].value
    assert_equal :eof, tokens[3].type
  end

  def test_tokenize_quoted_string
    tokens = tokenize('"hello world"')
    assert_equal 2, tokens.length
    assert_equal :quoted_string, tokens[0].type
    assert_equal "hello world", tokens[0].value
  end

  def test_tokenize_operators
    tokens = tokenize("from:amy@example.com OR to:bob@example.com")
    
    assert_equal 8, tokens.length
    assert_equal :word, tokens[0].type
    assert_equal "from", tokens[0].value
    assert_equal :colon, tokens[1].type
    assert_equal :email, tokens[2].type
    assert_equal "amy@example.com", tokens[2].value
    assert_equal :or, tokens[3].type
    assert_equal :word, tokens[4].type
    assert_equal "to", tokens[4].value
    assert_equal :colon, tokens[5].type
    assert_equal :email, tokens[6].type
    assert_equal "bob@example.com", tokens[6].value
    assert_equal :eof, tokens[7].type
  end

  def test_tokenize_parentheses
    tokens = tokenize("subject:(meeting call)")
    
    assert_equal 7, tokens.length
    assert_equal :word, tokens[0].type
    assert_equal "subject", tokens[0].value
    assert_equal :colon, tokens[1].type
    assert_equal :lparen, tokens[2].type
    assert_equal :word, tokens[3].type
    assert_equal "meeting", tokens[3].value
    assert_equal :word, tokens[4].type
    assert_equal "call", tokens[4].value
    assert_equal :rparen, tokens[5].type
    assert_equal :eof, tokens[6].type
  end

  def test_tokenize_braces
    tokens = tokenize("{from:a from:b}")
    
    assert_equal 9, tokens.length
    assert_equal :lbrace, tokens[0].type
    assert_equal :word, tokens[1].type
    assert_equal "from", tokens[1].value
    assert_equal :colon, tokens[2].type
    assert_equal :word, tokens[3].type
    assert_equal "a", tokens[3].value
    assert_equal :word, tokens[4].type
    assert_equal "from", tokens[4].value
    assert_equal :colon, tokens[5].type
    assert_equal :word, tokens[6].type
    assert_equal "b", tokens[6].value
    assert_equal :rbrace, tokens[7].type
    assert_equal :eof, tokens[8].type
  end

  def test_tokenize_negation
    tokens = tokenize("dinner -movie")
    assert_equal 4, tokens.length
    assert_equal :word, tokens[0].type
    assert_equal "dinner", tokens[0].value
    assert_equal :minus, tokens[1].type
    assert_equal :word, tokens[2].type
    assert_equal "movie", tokens[2].value
  end

  def test_tokenize_around
    tokens = tokenize("holiday AROUND 10 vacation")
    
    assert_equal 5, tokens.length
    assert_equal :word, tokens[0].type
    assert_equal "holiday", tokens[0].value
    assert_equal :around, tokens[1].type
    assert_equal :number, tokens[2].type
    assert_equal 10, tokens[2].value
    assert_equal :word, tokens[3].type
    assert_equal "vacation", tokens[3].value
    assert_equal :eof, tokens[4].type
  end

  def test_tokenize_date
    tokens = tokenize("after:2004/04/16")
    assert_equal 4, tokens.length
    assert_equal :word, tokens[0].type
    assert_equal "after", tokens[0].value
    assert_equal :colon, tokens[1].type
    assert_equal :date, tokens[2].type
    assert_equal "2004/04/16", tokens[2].value
  end

  def test_tokenize_relative_time
    tokens = tokenize("older_than:1y")
    assert_equal 4, tokens.length
    assert_equal :word, tokens[0].type
    assert_equal "older_than", tokens[0].value
    assert_equal :colon, tokens[1].type
    assert_equal :relative_time, tokens[2].type
    assert_equal "1y", tokens[2].value
  end

  def test_tokenize_number
    tokens = tokenize("size:1000000")
    assert_equal 4, tokens.length
    assert_equal :word, tokens[0].type
    assert_equal "size", tokens[0].value
    assert_equal :colon, tokens[1].type
    assert_equal :number, tokens[2].type
    assert_equal 1000000, tokens[2].value
  end

  def test_tokenize_and_operator
    tokens = tokenize("from:amy@example.com AND to:bob@example.com")
    
    and_token = tokens.find { |t| t.type == :and }
    refute_nil and_token
    assert_equal "AND", and_token.value
  end

  def test_tokenize_plus
    tokens = tokenize("+unicorn")
    assert_equal 3, tokens.length
    assert_equal :plus, tokens[0].type
    assert_equal :word, tokens[1].type
    assert_equal "unicorn", tokens[1].value
  end

  def test_tokenize_complex_query
    tokens = tokenize('from:boss@example.com subject:"urgent meeting" has:attachment')
    
    assert_equal 10, tokens.length
    assert_equal :word, tokens[0].type
    assert_equal "from", tokens[0].value
    assert_equal :colon, tokens[1].type
    assert_equal :email, tokens[2].type
    assert_equal "boss@example.com", tokens[2].value
    assert_equal :word, tokens[3].type
    assert_equal "subject", tokens[3].value
    assert_equal :colon, tokens[4].type
    assert_equal :quoted_string, tokens[5].type
    assert_equal "urgent meeting", tokens[5].value
    assert_equal :word, tokens[6].type
    assert_equal "has", tokens[6].value
    assert_equal :colon, tokens[7].type
    assert_equal :word, tokens[8].type
    assert_equal "attachment", tokens[8].value
    assert_equal :eof, tokens[9].type
  end

  def test_tokenize_email_with_plus
    tokens = tokenize("to:user+tag@example.com")
    email_token = tokens.find { |t| t.type == :email }
    assert_equal "user+tag@example.com", email_token.value
  end

  def test_tokenize_multiple_words
    tokens = tokenize("project report meeting")
    word_tokens = tokens.select { |t| t.type == :word }
    assert_equal 3, word_tokens.length
    assert_equal "project", word_tokens[0].value
    assert_equal "report", word_tokens[1].value
    assert_equal "meeting", word_tokens[2].value
  end
end

