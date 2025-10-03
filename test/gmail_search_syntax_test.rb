require "test_helper"

class GmailSearchSyntaxTest < Minitest::Test
  include GmailSearchSyntax::AST

  def test_version
    assert_equal "0.1.0", GmailSearchSyntax::VERSION
  end

  def test_simple_from_operator
    ast = GmailSearchSyntax.parse!("from:amy@example.com")
    assert_instance_of Operator, ast
    assert_equal "from", ast.name
    assert_equal "amy@example.com", ast.value
  end

  def test_from_me
    ast = GmailSearchSyntax.parse!("from:me")
    assert_instance_of Operator, ast
    assert_equal "from", ast.name
    assert_equal "me", ast.value
  end

  def test_to_operator
    ast = GmailSearchSyntax.parse!("to:john@example.com")
    assert_instance_of Operator, ast
    assert_equal "to", ast.name
    assert_equal "john@example.com", ast.value
  end

  def test_subject_with_single_word
    ast = GmailSearchSyntax.parse!("subject:dinner")
    assert_instance_of Operator, ast
    assert_equal "subject", ast.name
    assert_equal "dinner", ast.value
  end

  def test_subject_with_quoted_phrase
    ast = GmailSearchSyntax.parse!('subject:"anniversary party"')
    assert_instance_of Operator, ast
    assert_equal "subject", ast.name
    assert_equal "anniversary party", ast.value
  end

  def test_after_date
    ast = GmailSearchSyntax.parse!("after:2004/04/16")
    assert_instance_of Operator, ast
    assert_equal "after", ast.name
    assert_equal "2004/04/16", ast.value
  end

  def test_before_date
    ast = GmailSearchSyntax.parse!("before:04/18/2004")
    assert_instance_of Operator, ast
    assert_equal "before", ast.name
    assert_equal "04/18/2004", ast.value
  end

  def test_older_than_relative
    ast = GmailSearchSyntax.parse!("older_than:1y")
    assert_instance_of Operator, ast
    assert_equal "older_than", ast.name
    assert_equal "1y", ast.value
  end

  def test_newer_than_relative
    ast = GmailSearchSyntax.parse!("newer_than:2d")
    assert_instance_of Operator, ast
    assert_equal "newer_than", ast.name
    assert_equal "2d", ast.value
  end

  def test_or_operator_with_from
    ast = GmailSearchSyntax.parse!("from:amy OR from:david")
    assert_instance_of Or, ast
    
    assert_equal 2, ast.operands.length
    assert_instance_of Operator, ast.operands[0]
    assert_equal "from", ast.operands[0].name
    assert_equal "amy", ast.operands[0].value
    
    assert_instance_of Operator, ast.operands[1]
    assert_equal "from", ast.operands[1].name
    assert_equal "david", ast.operands[1].value
  end

  def test_braces_as_or
    ast = GmailSearchSyntax.parse!("{from:amy from:david}")
    assert_instance_of Or, ast
    
    assert_equal 2, ast.operands.length
    assert_instance_of Operator, ast.operands[0]
    assert_equal "from", ast.operands[0].name
    assert_equal "amy", ast.operands[0].value
    
    assert_instance_of Operator, ast.operands[1]
    assert_equal "from", ast.operands[1].name
    assert_equal "david", ast.operands[1].value
  end

  def test_and_operator
    ast = GmailSearchSyntax.parse!("from:amy AND to:david")
    assert_instance_of And, ast
    
    assert_equal 2, ast.operands.length
    assert_instance_of Operator, ast.operands[0]
    assert_equal "from", ast.operands[0].name
    assert_equal "amy", ast.operands[0].value
    
    assert_instance_of Operator, ast.operands[1]
    assert_equal "to", ast.operands[1].name
    assert_equal "david", ast.operands[1].value
  end

  def test_implicit_and
    ast = GmailSearchSyntax.parse!("from:amy to:david")
    assert_instance_of And, ast
    
    assert_equal 2, ast.operands.length
    assert_instance_of Operator, ast.operands[0]
    assert_equal "from", ast.operands[0].name
    
    assert_instance_of Operator, ast.operands[1]
    assert_equal "to", ast.operands[1].name
  end

  def test_negation_with_minus
    ast = GmailSearchSyntax.parse!("dinner -movie")
    assert_instance_of And, ast
    
    assert_equal 2, ast.operands.length
    assert_instance_of Text, ast.operands[0]
    assert_equal "dinner", ast.operands[0].value
    
    assert_instance_of Not, ast.operands[1]
    assert_instance_of Text, ast.operands[1].child
    assert_equal "movie", ast.operands[1].child.value
  end

  def test_around_operator
    ast = GmailSearchSyntax.parse!("holiday AROUND 10 vacation")
    assert_instance_of Around, ast
    
    assert_instance_of Text, ast.left
    assert_equal "holiday", ast.left.value
    assert_equal 10, ast.distance
    
    assert_instance_of Text, ast.right
    assert_equal "vacation", ast.right.value
  end

  def test_around_with_quoted_string
    ast = GmailSearchSyntax.parse!('"secret AROUND 25 birthday"')
    assert_instance_of Text, ast
    assert_equal "secret AROUND 25 birthday", ast.value
  end

  def test_label_operator
    ast = GmailSearchSyntax.parse!("label:friends")
    assert_instance_of Operator, ast
    assert_equal "label", ast.name
    assert_equal "friends", ast.value
  end

  def test_category_operator
    ast = GmailSearchSyntax.parse!("category:primary")
    assert_instance_of Operator, ast
    assert_equal "category", ast.name
    assert_equal "primary", ast.value
  end

  def test_has_attachment
    ast = GmailSearchSyntax.parse!("has:attachment")
    assert_instance_of Operator, ast
    assert_equal "has", ast.name
    assert_equal "attachment", ast.value
  end

  def test_filename_operator
    ast = GmailSearchSyntax.parse!("filename:pdf")
    assert_instance_of Operator, ast
    assert_equal "filename", ast.name
    assert_equal "pdf", ast.value
  end

  def test_filename_with_extension
    ast = GmailSearchSyntax.parse!("filename:homework.txt")
    assert_instance_of Operator, ast
    assert_equal "filename", ast.name
    assert_equal "homework.txt", ast.value
  end

  def test_quoted_exact_phrase
    ast = GmailSearchSyntax.parse!('"dinner and movie tonight"')
    assert_instance_of Text, ast
    assert_equal "dinner and movie tonight", ast.value
  end

  def test_parentheses_grouping
    ast = GmailSearchSyntax.parse!("subject:(dinner movie)")
    assert_instance_of Operator, ast
    assert_equal "subject", ast.name
    
    assert_instance_of And, ast.value
    assert_equal 2, ast.value.operands.length
    assert_instance_of Text, ast.value.operands[0]
    assert_equal "dinner", ast.value.operands[0].value
    assert_instance_of Text, ast.value.operands[1]
    assert_equal "movie", ast.value.operands[1].value
  end

  def test_in_anywhere
    ast = GmailSearchSyntax.parse!("in:anywhere movie")
    assert_instance_of And, ast
    
    assert_equal 2, ast.operands.length
    assert_instance_of Operator, ast.operands[0]
    assert_equal "in", ast.operands[0].name
    assert_equal "anywhere", ast.operands[0].value
    
    assert_instance_of Text, ast.operands[1]
    assert_equal "movie", ast.operands[1].value
  end

  def test_is_starred
    ast = GmailSearchSyntax.parse!("is:starred")
    assert_instance_of Operator, ast
    assert_equal "is", ast.name
    assert_equal "starred", ast.value
  end

  def test_is_unread
    ast = GmailSearchSyntax.parse!("is:unread")
    assert_instance_of Operator, ast
    assert_equal "is", ast.name
    assert_equal "unread", ast.value
  end

  def test_size_operator
    ast = GmailSearchSyntax.parse!("size:1000000")
    assert_instance_of Operator, ast
    assert_equal "size", ast.name
    assert_equal 1000000, ast.value
  end

  def test_larger_operator
    ast = GmailSearchSyntax.parse!("larger:10M")
    assert_instance_of Operator, ast
    assert_equal "larger", ast.name
    assert_equal "10M", ast.value
  end

  def test_complex_query_with_multiple_operators
    ast = GmailSearchSyntax.parse!("from:amy subject:meeting has:attachment")
    assert_instance_of And, ast
    
    assert_equal 3, ast.operands.length
    assert_instance_of Operator, ast.operands[0]
    assert_equal "from", ast.operands[0].name
    
    assert_instance_of Operator, ast.operands[1]
    assert_equal "subject", ast.operands[1].name
    
    assert_instance_of Operator, ast.operands[2]
    assert_equal "has", ast.operands[2].name
  end

  def test_complex_or_and_combination
    ast = GmailSearchSyntax.parse!("from:amy OR from:bob to:me")
    assert_instance_of Or, ast
    
    assert_equal 2, ast.operands.length
    assert_instance_of Operator, ast.operands[0]
    
    assert_instance_of And, ast.operands[1]
    assert_equal 2, ast.operands[1].operands.length
    assert_instance_of Operator, ast.operands[1].operands[0]
    assert_equal "from", ast.operands[1].operands[0].name
    assert_equal "bob", ast.operands[1].operands[0].value
    
    assert_instance_of Operator, ast.operands[1].operands[1]
    assert_equal "to", ast.operands[1].operands[1].name
  end

  def test_negation_with_operator
    ast = GmailSearchSyntax.parse!("-from:spam@example.com")
    assert_instance_of Not, ast
    assert_instance_of Operator, ast.child
    assert_equal "from", ast.child.name
    assert_equal "spam@example.com", ast.child.value
  end

  def test_list_operator
    ast = GmailSearchSyntax.parse!("list:info@example.com")
    assert_instance_of Operator, ast
    assert_equal "list", ast.name
    assert_equal "info@example.com", ast.value
  end

  def test_deliveredto_operator
    ast = GmailSearchSyntax.parse!("deliveredto:username@example.com")
    assert_instance_of Operator, ast
    assert_equal "deliveredto", ast.name
    assert_equal "username@example.com", ast.value
  end

  def test_rfc822msgid_operator
    ast = GmailSearchSyntax.parse!("rfc822msgid:200503292@example.com")
    assert_instance_of Operator, ast
    assert_equal "rfc822msgid", ast.name
    assert_equal "200503292@example.com", ast.value
  end

  def test_cc_operator
    ast = GmailSearchSyntax.parse!("cc:john@example.com")
    assert_instance_of Operator, ast
    assert_equal "cc", ast.name
    assert_equal "john@example.com", ast.value
  end

  def test_bcc_operator
    ast = GmailSearchSyntax.parse!("bcc:david@example.com")
    assert_instance_of Operator, ast
    assert_equal "bcc", ast.name
    assert_equal "david@example.com", ast.value
  end

  def test_plain_text_search
    ast = GmailSearchSyntax.parse!("meeting")
    assert_instance_of Text, ast
    assert_equal "meeting", ast.value
  end

  def test_multiple_plain_text_words
    ast = GmailSearchSyntax.parse!("project report")
    assert_instance_of And, ast
    
    assert_equal 2, ast.operands.length
    assert_instance_of Text, ast.operands[0]
    assert_equal "project", ast.operands[0].value
    
    assert_instance_of Text, ast.operands[1]
    assert_equal "report", ast.operands[1].value
  end

  def test_empty_query
    error = assert_raises(GmailSearchSyntax::EmptyQueryError) do
      GmailSearchSyntax.parse!("")
    end
    assert_equal "Query cannot be empty", error.message
  end

  def test_whitespace_only
    error = assert_raises(GmailSearchSyntax::EmptyQueryError) do
      GmailSearchSyntax.parse!("   ")
    end
    assert_equal "Query cannot be empty", error.message
  end

  def test_nested_parentheses_with_operators
    ast = GmailSearchSyntax.parse!("from:amy (subject:meeting OR subject:call)")
    assert_instance_of And, ast
    
    assert_equal 2, ast.operands.length
    assert_instance_of Operator, ast.operands[0]
    assert_equal "from", ast.operands[0].name
    
    assert_instance_of Or, ast.operands[1]
  end

  def test_multiple_negations
    ast = GmailSearchSyntax.parse!("-from:spam -subject:junk")
    assert_instance_of And, ast
    
    assert_equal 2, ast.operands.length
    assert_instance_of Not, ast.operands[0]
    assert_instance_of Operator, ast.operands[0].child
    assert_equal "from", ast.operands[0].child.name
    
    assert_instance_of Not, ast.operands[1]
    assert_instance_of Operator, ast.operands[1].child
    assert_equal "subject", ast.operands[1].child.name
  end

  def test_or_with_three_terms
    ast = GmailSearchSyntax.parse!("{from:a from:b from:c}")
    assert_instance_of Or, ast
    
    assert_equal 3, ast.operands.length
    assert_instance_of Operator, ast.operands[0]
    assert_equal "a", ast.operands[0].value
    assert_instance_of Operator, ast.operands[1]
    assert_equal "b", ast.operands[1].value
    assert_instance_of Operator, ast.operands[2]
    assert_equal "c", ast.operands[2].value
  end

  def test_complex_mixed_query
    ast = GmailSearchSyntax.parse!("from:boss subject:urgent has:attachment -label:archive")
    assert_instance_of And, ast
    
    assert_equal 4, ast.operands.length
    
    assert_instance_of Operator, ast.operands[0]
    assert_equal "from", ast.operands[0].name
    
    assert_instance_of Operator, ast.operands[1]
    assert_equal "subject", ast.operands[1].name
    
    assert_instance_of Operator, ast.operands[2]
    assert_equal "has", ast.operands[2].name
    
    assert_instance_of Not, ast.operands[3]
    assert_instance_of Operator, ast.operands[3].child
    assert_equal "label", ast.operands[3].child.name
  end

  def test_quoted_string_with_operators_inside
    ast = GmailSearchSyntax.parse!('"from:amy to:bob"')
    assert_instance_of Text, ast
    assert_equal "from:amy to:bob", ast.value
  end

  def test_email_with_plus_sign
    ast = GmailSearchSyntax.parse!("to:user+tag@example.com")
    assert_instance_of Operator, ast
    assert_equal "to", ast.name
    assert_equal "user+tag@example.com", ast.value
  end

  def test_in_operator_with_location
    ast = GmailSearchSyntax.parse!("in:inbox from:manager")
    assert_instance_of And, ast
    
    assert_equal 2, ast.operands.length
    assert_instance_of Operator, ast.operands[0]
    assert_equal "in", ast.operands[0].name
    assert_equal "inbox", ast.operands[0].value
  end

  def test_has_drive_operator
    ast = GmailSearchSyntax.parse!("has:drive")
    assert_instance_of Operator, ast
    assert_equal "has", ast.name
    assert_equal "drive", ast.value
  end

  def test_category_updates
    ast = GmailSearchSyntax.parse!("category:updates")
    assert_instance_of Operator, ast
    assert_equal "category", ast.name
    assert_equal "updates", ast.value
  end

  def test_around_default_distance
    ast = GmailSearchSyntax.parse!("meeting AROUND project")
    assert_instance_of Around, ast
    assert_equal 5, ast.distance
  end

  def test_parentheses_with_single_term
    ast = GmailSearchSyntax.parse!("(meeting)")
    assert_instance_of Text, ast
    assert_equal "meeting", ast.value
  end

  def test_subject_with_parentheses_multiple_words
    ast = GmailSearchSyntax.parse!("subject:(project status update)")
    assert_instance_of Operator, ast
    assert_equal "subject", ast.name
    
    assert_instance_of And, ast.value
    assert_equal 3, ast.value.operands.length
    assert_instance_of Text, ast.value.operands[0]
    assert_equal "project", ast.value.operands[0].value
    assert_instance_of Text, ast.value.operands[1]
    assert_equal "status", ast.value.operands[1].value
    assert_instance_of Text, ast.value.operands[2]
    assert_equal "update", ast.value.operands[2].value
  end

  def test_and_explicit_with_text
    ast = GmailSearchSyntax.parse!("meeting AND project")
    assert_instance_of And, ast
    
    assert_equal 2, ast.operands.length
    assert_instance_of Text, ast.operands[0]
    assert_equal "meeting", ast.operands[0].value
    
    assert_instance_of Text, ast.operands[1]
    assert_equal "project", ast.operands[1].value
  end

  def test_smaller_operator
    ast = GmailSearchSyntax.parse!("smaller:1M")
    assert_instance_of Operator, ast
    assert_equal "smaller", ast.name
    assert_equal "1M", ast.value
  end
end
