require "test_helper"

class GmailSearchSyntaxTest < Minitest::Test
  include GmailSearchSyntax::AST

  def assert_operator(expected_properties, actual_operator)
    assert_instance_of Operator, actual_operator, "Expected Operator, got #{actual_operator.class}"
    expected_properties.each do |property, expected_value|
      actual_value = actual_operator.public_send(property)
      if property == :operands && expected_value.is_a?(Array)
        assert_equal expected_value.length, actual_value.length, "Expected #{expected_value.length} operands, got #{actual_value.length}"
        expected_value.each_with_index do |expected_operand, index|
          if expected_operand.is_a?(Hash)
            if expected_operand.key?(:name) && expected_operand.key?(:value)
              # This is an Operator specification
              assert_operator(expected_operand, actual_value[index])
            elsif expected_operand.key?(:value)
              # This is a LooseWord specification
              assert_string_token(expected_operand, actual_value[index])
            else
              # Generic node assertion
              assert_equal expected_operand, actual_value[index], "Operand #{index}: expected #{expected_operand.inspect}, got #{actual_value[index].inspect}"
            end
          else
            assert_equal expected_operand, actual_value[index], "Operand #{index}: expected #{expected_operand.inspect}, got #{actual_value[index].inspect}"
          end
        end
      elsif expected_value.is_a?(Class)
        assert_instance_of expected_value, actual_value, "Operator: expected #{property} to be instance of #{expected_value}, got #{actual_value.class}"
      else
        assert_equal expected_value, actual_value, "Operator: expected #{property} to be #{expected_value.inspect}, got #{actual_value.inspect}"
      end
    end
  end

  def assert_string_token(expected_properties, actual_string_token)
    assert_instance_of LooseWord, actual_string_token, "Expected LooseWord, got #{actual_string_token.class}"
    expected_properties.each do |property, expected_value|
      actual_value = actual_string_token.public_send(property)
      assert_equal expected_value, actual_value, "LooseWord: expected #{property} to be #{expected_value.inspect}, got #{actual_value.inspect}"
    end
  end

  def test_version
    assert GmailSearchSyntax::VERSION
  end

  def test_simple_from_operator
    ast = GmailSearchSyntax.parse!("from:amy@example.com")
    assert_operator({name: "from", value: "amy@example.com"}, ast)
  end

  def test_from_me
    ast = GmailSearchSyntax.parse!("from:me")
    assert_operator({name: "from", value: "me"}, ast)
  end

  def test_to_operator
    ast = GmailSearchSyntax.parse!("to:john@example.com")
    assert_operator({name: "to", value: "john@example.com"}, ast)
  end

  def test_subject_with_single_word
    ast = GmailSearchSyntax.parse!("subject:dinner")
    assert_operator({name: "subject", value: "dinner"}, ast)
  end

  def test_subject_with_quoted_phrase
    ast = GmailSearchSyntax.parse!('subject:"anniversary party"')
    assert_operator({name: "subject", value: "anniversary party"}, ast)
  end

  def test_after_date
    ast = GmailSearchSyntax.parse!("after:2004/04/16")
    assert_operator({name: "after", value: "2004/04/16"}, ast)
  end

  def test_before_date
    ast = GmailSearchSyntax.parse!("before:04/18/2004")
    assert_operator({name: "before", value: "04/18/2004"}, ast)
  end

  def test_older_than_relative
    ast = GmailSearchSyntax.parse!("older_than:1y")
    assert_operator({name: "older_than", value: "1y"}, ast)
  end

  def test_newer_than_relative
    ast = GmailSearchSyntax.parse!("newer_than:2d")
    assert_operator({name: "newer_than", value: "2d"}, ast)
  end

  def test_or_operator_with_from
    ast = GmailSearchSyntax.parse!("from:amy OR from:david")
    assert_instance_of Or, ast

    assert_equal 2, ast.operands.length
    assert_operator({name: "from", value: "amy"}, ast.operands[0])
    assert_operator({name: "from", value: "david"}, ast.operands[1])
  end

  def test_braces_as_or
    ast = GmailSearchSyntax.parse!("{from:amy from:david}")
    assert_instance_of Or, ast

    assert_equal 2, ast.operands.length
    assert_operator({name: "from", value: "amy"}, ast.operands[0])
    assert_operator({name: "from", value: "david"}, ast.operands[1])
  end

  def test_and_operator
    ast = GmailSearchSyntax.parse!("from:amy AND to:david")
    assert_instance_of And, ast

    assert_equal 2, ast.operands.length
    assert_operator({name: "from", value: "amy"}, ast.operands[0])
    assert_operator({name: "to", value: "david"}, ast.operands[1])
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
    assert_instance_of LooseWord, ast.operands[0]
    assert_equal "dinner", ast.operands[0].value

    assert_instance_of Not, ast.operands[1]
    assert_instance_of LooseWord, ast.operands[1].child
    assert_equal "movie", ast.operands[1].child.value
  end

  # Gmail behavior: embedded hyphens (no preceding whitespace) are word separators, not negation
  # "Coxlee-Gammage" → Coxlee AND Gammage (both tokens highlighted)
  # "Coxlee -Gammage" → Coxlee AND NOT Gammage (space+hyphen = negation)

  def test_embedded_hyphen_is_word_separator
    # Gmail behavior: hyphen without preceding whitespace separates words, not negation
    ast = GmailSearchSyntax.parse!("some-outfit")
    assert_instance_of And, ast

    assert_equal 2, ast.operands.length
    assert_instance_of LooseWord, ast.operands[0]
    assert_equal "some", ast.operands[0].value

    assert_instance_of LooseWord, ast.operands[1]
    assert_equal "outfit", ast.operands[1].value
  end

  def test_embedded_hyphen_multiple
    # Multiple hyphens: a-b-c → a AND b AND c
    ast = GmailSearchSyntax.parse!("a-b-c")
    assert_instance_of And, ast

    assert_equal 3, ast.operands.length
    assert_equal "a", ast.operands[0].value
    assert_equal "b", ast.operands[1].value
    assert_equal "c", ast.operands[2].value
  end

  def test_embedded_hyphen_real_name
    # Real-world case: hyphenated names
    ast = GmailSearchSyntax.parse!("Coxlee-Gammage")
    assert_instance_of And, ast

    assert_equal 2, ast.operands.length
    assert_equal "Coxlee", ast.operands[0].value
    assert_equal "Gammage", ast.operands[1].value
  end

  def test_space_hyphen_is_negation
    # Space + hyphen = negation (unchanged behavior)
    ast = GmailSearchSyntax.parse!("cats -dogs")
    assert_instance_of And, ast

    assert_equal 2, ast.operands.length
    assert_instance_of LooseWord, ast.operands[0]
    assert_equal "cats", ast.operands[0].value

    assert_instance_of Not, ast.operands[1]
    assert_equal "dogs", ast.operands[1].child.value
  end

  def test_embedded_hyphen_combined_with_negation
    # Mixed: embedded hyphen + space-preceded negation
    ast = GmailSearchSyntax.parse!("some-outfit -dogs")
    assert_instance_of And, ast

    assert_equal 3, ast.operands.length
    assert_equal "some", ast.operands[0].value
    assert_equal "outfit", ast.operands[1].value
    assert_instance_of Not, ast.operands[2]
    assert_equal "dogs", ast.operands[2].child.value
  end

  def test_negation_at_start_of_input
    # Negation at start of input still works
    ast = GmailSearchSyntax.parse!("-spam")
    assert_instance_of Not, ast
    assert_equal "spam", ast.child.value
  end

  def test_embedded_hyphen_with_operator
    # Gmail keeps hyphens in operator values: from:mary-jane → operator with value "mary-jane"
    ast = GmailSearchSyntax.parse!("from:mary-jane")
    assert_instance_of Operator, ast
    assert_equal "from", ast.name
    assert_equal "mary-jane", ast.value
  end

  def test_hyphenated_label_name
    # Common case: label names with hyphens
    ast = GmailSearchSyntax.parse!("label:work-projects")
    assert_instance_of Operator, ast
    assert_equal "label", ast.name
    assert_equal "work-projects", ast.value
  end

  def test_multiple_hyphens_in_operator_value
    ast = GmailSearchSyntax.parse!("label:starter-league-thisforthat")
    assert_instance_of Operator, ast
    assert_equal "label", ast.name
    assert_equal "starter-league-thisforthat", ast.value
  end

  def test_around_operator
    ast = GmailSearchSyntax.parse!("holiday AROUND 10 vacation")
    assert_instance_of Around, ast

    assert_instance_of LooseWord, ast.left
    assert_equal "holiday", ast.left.value
    assert_equal 10, ast.distance

    assert_instance_of LooseWord, ast.right
    assert_equal "vacation", ast.right.value
  end

  def test_around_with_quoted_string
    ast = GmailSearchSyntax.parse!('"secret AROUND 25 birthday"')
    assert_instance_of ExactWord, ast
    assert_equal "secret AROUND 25 birthday", ast.value
  end

  def test_label_operator
    ast = GmailSearchSyntax.parse!("label:friends")
    assert_operator({name: "label", value: "friends"}, ast)
  end

  def test_category_operator
    ast = GmailSearchSyntax.parse!("category:primary")
    assert_operator({name: "category", value: "primary"}, ast)
  end

  def test_has_attachment
    ast = GmailSearchSyntax.parse!("has:attachment")
    assert_operator({name: "has", value: "attachment"}, ast)
  end

  def test_filename_operator
    ast = GmailSearchSyntax.parse!("filename:pdf")
    assert_operator({name: "filename", value: "pdf"}, ast)
  end

  def test_filename_with_extension
    ast = GmailSearchSyntax.parse!("filename:homework.txt")
    assert_operator({name: "filename", value: "homework.txt"}, ast)
  end

  def test_quoted_exact_phrase
    ast = GmailSearchSyntax.parse!('"dinner and movie tonight"')
    assert_instance_of ExactWord, ast
    assert_equal "dinner and movie tonight", ast.value
  end

  def test_parentheses_grouping
    ast = GmailSearchSyntax.parse!("subject:(dinner movie)")
    assert_operator({name: "subject", value: And}, ast)
    assert_equal 2, ast.value.operands.length
    assert_string_token({value: "dinner"}, ast.value.operands[0])
    assert_string_token({value: "movie"}, ast.value.operands[1])
  end

  def test_in_anywhere
    # Gmail treats barewords after operator as separate search terms
    # in:anywhere movie → search for "movie" in all mail locations
    ast = GmailSearchSyntax.parse!("in:anywhere movie")
    assert_instance_of And, ast
    assert_equal 2, ast.operands.length
    assert_operator({name: "in", value: "anywhere"}, ast.operands[0])
    assert_string_token({value: "movie"}, ast.operands[1])
  end

  def test_is_starred
    ast = GmailSearchSyntax.parse!("is:starred")
    assert_operator({name: "is", value: "starred"}, ast)
  end

  def test_is_unread
    ast = GmailSearchSyntax.parse!("is:unread")
    assert_operator({name: "is", value: "unread"}, ast)
  end

  def test_size_operator
    ast = GmailSearchSyntax.parse!("size:1000000")
    assert_operator({name: "size", value: 1000000}, ast)
  end

  def test_larger_operator
    ast = GmailSearchSyntax.parse!("larger:10M")
    assert_operator({name: "larger", value: "10M"}, ast)
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
    assert_operator({name: "list", value: "info@example.com"}, ast)
  end

  def test_deliveredto_operator
    ast = GmailSearchSyntax.parse!("deliveredto:username@example.com")
    assert_operator({name: "deliveredto", value: "username@example.com"}, ast)
  end

  def test_rfc822msgid_operator
    ast = GmailSearchSyntax.parse!("rfc822msgid:200503292@example.com")
    assert_operator({name: "rfc822msgid", value: "200503292@example.com"}, ast)
  end

  def test_cc_operator
    ast = GmailSearchSyntax.parse!("cc:john@example.com")
    assert_operator({name: "cc", value: "john@example.com"}, ast)
  end

  def test_bcc_operator
    ast = GmailSearchSyntax.parse!("bcc:david@example.com")
    assert_operator({name: "bcc", value: "david@example.com"}, ast)
  end

  def test_plain_text_search
    ast = GmailSearchSyntax.parse!("meeting")
    assert_instance_of LooseWord, ast
    assert_equal "meeting", ast.value
  end

  def test_multiple_plain_text_words
    ast = GmailSearchSyntax.parse!("project report")
    assert_instance_of And, ast

    assert_equal 2, ast.operands.length
    assert_instance_of LooseWord, ast.operands[0]
    assert_equal "project", ast.operands[0].value

    assert_instance_of LooseWord, ast.operands[1]
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
    assert_instance_of ExactWord, ast
    assert_equal "from:amy to:bob", ast.value
  end

  def test_email_with_plus_sign
    ast = GmailSearchSyntax.parse!("to:user+tag@example.com")
    assert_operator({name: "to", value: "user+tag@example.com"}, ast)
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
    assert_operator({name: "has", value: "drive"}, ast)
  end

  def test_category_updates
    ast = GmailSearchSyntax.parse!("category:updates")
    assert_operator({name: "category", value: "updates"}, ast)
  end

  def test_around_default_distance
    ast = GmailSearchSyntax.parse!("meeting AROUND project")
    assert_instance_of Around, ast
    assert_equal 5, ast.distance
  end

  def test_parentheses_with_single_term
    ast = GmailSearchSyntax.parse!("(meeting)")
    assert_instance_of LooseWord, ast
    assert_equal "meeting", ast.value
  end

  def test_subject_with_parentheses_multiple_words
    ast = GmailSearchSyntax.parse!("subject:(project status update)")
    assert_operator({name: "subject", value: And}, ast)
    assert_equal 3, ast.value.operands.length
    assert_string_token({value: "project"}, ast.value.operands[0])
    assert_string_token({value: "status"}, ast.value.operands[1])
    assert_string_token({value: "update"}, ast.value.operands[2])
  end

  def test_and_explicit_with_text
    ast = GmailSearchSyntax.parse!("meeting AND project")
    assert_instance_of And, ast

    assert_equal 2, ast.operands.length
    assert_instance_of LooseWord, ast.operands[0]
    assert_equal "meeting", ast.operands[0].value

    assert_instance_of LooseWord, ast.operands[1]
    assert_equal "project", ast.operands[1].value
  end

  def test_smaller_operator
    ast = GmailSearchSyntax.parse!("smaller:1M")
    assert_operator({name: "smaller", value: "1M"}, ast)
  end

  def test_or_inside_operator_value
    ast = GmailSearchSyntax.parse!("from:(mischa@ OR julik@)")
    assert_operator({name: "from", value: Or}, ast)
    assert_equal 2, ast.value.operands.length
    assert_string_token({value: "mischa@"}, ast.value.operands[0])
    assert_string_token({value: "julik@"}, ast.value.operands[1])
  end

  def test_or_with_emails_inside_operator
    ast = GmailSearchSyntax.parse!("from:(amy@example.com OR bob@example.com)")
    assert_operator({name: "from", value: Or}, ast)
    assert_equal 2, ast.value.operands.length
    assert_string_token({value: "amy@example.com"}, ast.value.operands[0])
    assert_string_token({value: "bob@example.com"}, ast.value.operands[1])
  end

  def test_multiple_or_inside_operator
    ast = GmailSearchSyntax.parse!("from:(a@ OR b@ OR c@)")
    assert_operator({name: "from", value: Or}, ast)
    assert_equal 3, ast.value.operands.length
    assert_equal "a@", ast.value.operands[0].value
    assert_equal "b@", ast.value.operands[1].value
    assert_equal "c@", ast.value.operands[2].value
  end

  def test_and_inside_operator_value
    ast = GmailSearchSyntax.parse!("subject:(urgent AND meeting)")
    assert_operator({name: "subject", value: And}, ast)
    assert_equal 2, ast.value.operands.length
    assert_string_token({value: "urgent"}, ast.value.operands[0])
    assert_string_token({value: "meeting"}, ast.value.operands[1])
  end

  def test_operator_with_or_combined_with_other_conditions
    ast = GmailSearchSyntax.parse!("from:(alice@ OR bob@) subject:meeting")
    assert_instance_of And, ast

    assert_equal 2, ast.operands.length
    assert_instance_of Operator, ast.operands[0]
    assert_equal "from", ast.operands[0].name
    assert_instance_of Or, ast.operands[0].value

    assert_instance_of Operator, ast.operands[1]
    assert_equal "subject", ast.operands[1].name
    assert_equal "meeting", ast.operands[1].value
  end

  def test_negation_inside_operator_value
    ast = GmailSearchSyntax.parse!("subject:(meeting -cancelled)")
    assert_operator({name: "subject", value: And}, ast)
    assert_equal 2, ast.value.operands.length
    assert_string_token({value: "meeting"}, ast.value.operands[0])
    assert_instance_of Not, ast.value.operands[1]
    assert_equal "cancelled", ast.value.operands[1].child.value
  end

  def test_complex_expression_inside_operator
    ast = GmailSearchSyntax.parse!("from:(alice@ OR bob@) to:(charlie@ OR david@)")
    assert_instance_of And, ast

    assert_equal 2, ast.operands.length

    assert_instance_of Operator, ast.operands[0]
    assert_equal "from", ast.operands[0].name
    assert_instance_of Or, ast.operands[0].value
    assert_equal 2, ast.operands[0].value.operands.length

    assert_instance_of Operator, ast.operands[1]
    assert_equal "to", ast.operands[1].name
    assert_instance_of Or, ast.operands[1].value
    assert_equal 2, ast.operands[1].value.operands.length
  end

  def test_nested_parentheses_in_operator_value
    ast = GmailSearchSyntax.parse!("subject:((urgent OR important) meeting)")
    assert_instance_of Operator, ast
    assert_equal "subject", ast.name

    assert_instance_of And, ast.value
    assert_equal 2, ast.value.operands.length
    assert_instance_of Or, ast.value.operands[0]
    assert_equal 2, ast.value.operands[0].operands.length
    assert_equal "urgent", ast.value.operands[0].operands[0].value
    assert_equal "important", ast.value.operands[0].operands[1].value
    assert_instance_of LooseWord, ast.value.operands[1]
    assert_equal "meeting", ast.value.operands[1].value
  end

  def test_curly_braces_inside_operator_value
    ast = GmailSearchSyntax.parse!("from:{mischa@ marc@}")
    assert_operator({name: "from", value: Or}, ast)
    assert_equal 2, ast.value.operands.length
    assert_string_token({value: "mischa@"}, ast.value.operands[0])
    assert_string_token({value: "marc@"}, ast.value.operands[1])
  end

  def test_curly_braces_with_emails_inside_operator
    ast = GmailSearchSyntax.parse!("from:{amy@example.com bob@example.com}")
    assert_instance_of Operator, ast
    assert_equal "from", ast.name

    assert_instance_of Or, ast.value
    assert_equal 2, ast.value.operands.length
    assert_equal "amy@example.com", ast.value.operands[0].value
    assert_equal "bob@example.com", ast.value.operands[1].value
  end

  def test_multiple_items_in_curly_braces
    ast = GmailSearchSyntax.parse!("from:{a@ b@ c@ d@}")
    assert_instance_of Operator, ast
    assert_equal "from", ast.name

    assert_instance_of Or, ast.value
    assert_equal 4, ast.value.operands.length
    assert_equal "a@", ast.value.operands[0].value
    assert_equal "b@", ast.value.operands[1].value
    assert_equal "c@", ast.value.operands[2].value
    assert_equal "d@", ast.value.operands[3].value
  end

  def test_curly_braces_combined_with_other_conditions
    ast = GmailSearchSyntax.parse!("from:{alice@ bob@} subject:meeting")
    assert_instance_of And, ast

    assert_equal 2, ast.operands.length
    assert_instance_of Operator, ast.operands[0]
    assert_equal "from", ast.operands[0].name
    assert_instance_of Or, ast.operands[0].value
    assert_equal 2, ast.operands[0].value.operands.length

    assert_instance_of Operator, ast.operands[1]
    assert_equal "subject", ast.operands[1].name
    assert_equal "meeting", ast.operands[1].value
  end

  def test_multiple_operators_with_curly_braces
    ast = GmailSearchSyntax.parse!("from:{alice@ bob@} to:{charlie@ david@}")
    assert_instance_of And, ast

    assert_equal 2, ast.operands.length

    assert_instance_of Operator, ast.operands[0]
    assert_equal "from", ast.operands[0].name
    assert_instance_of Or, ast.operands[0].value

    assert_instance_of Operator, ast.operands[1]
    assert_equal "to", ast.operands[1].name
    assert_instance_of Or, ast.operands[1].value
  end

  def test_mixing_parentheses_and_curly_braces
    ast = GmailSearchSyntax.parse!("from:{alice@ bob@} subject:(urgent meeting)")
    assert_instance_of And, ast

    assert_equal 2, ast.operands.length
    assert_instance_of Operator, ast.operands[0]
    assert_equal "from", ast.operands[0].name
    assert_instance_of Or, ast.operands[0].value

    assert_instance_of Operator, ast.operands[1]
    assert_equal "subject", ast.operands[1].name
    assert_instance_of And, ast.operands[1].value
  end

  def test_quoted_string_with_escaped_quotes
    ast = GmailSearchSyntax.parse!('"She said \\"hello\\" to me"')
    assert_instance_of ExactWord, ast
    assert_equal 'She said "hello" to me', ast.value
  end

  def test_quoted_string_with_escaped_backslash
    ast = GmailSearchSyntax.parse!('"path\\\\to\\\\file"')
    assert_instance_of ExactWord, ast
    assert_equal 'path\\to\\file', ast.value
  end

  def test_subject_with_escaped_quotes
    ast = GmailSearchSyntax.parse!('subject:"Meeting: \\"Q1 Review\\""')
    assert_instance_of Operator, ast
    assert_equal "subject", ast.name
    assert_equal 'Meeting: "Q1 Review"', ast.value
  end

  def test_unquoted_text_with_escaped_quote
    ast = GmailSearchSyntax.parse!('meeting\\"room')
    assert_instance_of LooseWord, ast
    assert_equal 'meeting"room', ast.value
  end

  def test_unquoted_text_with_escaped_backslash
    ast = GmailSearchSyntax.parse!('path\\\\to\\\\file')
    assert_instance_of LooseWord, ast
    assert_equal 'path\\to\\file', ast.value
  end

  def test_operator_with_unquoted_escaped_quote
    ast = GmailSearchSyntax.parse!('subject:test\\"value')
    assert_instance_of Operator, ast
    assert_equal "subject", ast.name
    assert_equal 'test"value', ast.value
  end

  def test_multiple_tokens_with_escapes
    ast = GmailSearchSyntax.parse!('meeting\\"room project\\\\plan')
    assert_instance_of And, ast
    assert_equal 2, ast.operands.length
    assert_equal 'meeting"room', ast.operands[0].value
    assert_equal 'project\\plan', ast.operands[1].value
  end

  # Gmail behavior: barewords after operator values are treated as separate search terms.
  # Multi-word operator values must be explicitly quoted: label:"Cora/Google Drive"

  def test_label_with_space_separated_value_gmail_behavior
    # Gmail treats barewords as separate search terms
    # To search for label "Cora/Google Drive", you must quote it: label:"Cora/Google Drive"
    ast = GmailSearchSyntax.parse!("label:Cora/Google Drive label:Notes")
    assert_instance_of And, ast
    assert_equal 3, ast.operands.length

    # First operator takes only the first token
    assert_instance_of Operator, ast.operands[0]
    assert_equal "label", ast.operands[0].name
    assert_equal "Cora/Google", ast.operands[0].value

    # "Drive" becomes a separate search term
    assert_instance_of LooseWord, ast.operands[1]
    assert_equal "Drive", ast.operands[1].value

    # Second operator parsed correctly
    assert_instance_of Operator, ast.operands[2]
    assert_equal "label", ast.operands[2].name
    assert_equal "Notes", ast.operands[2].value
  end

  def test_subject_with_barewords_gmail_behavior
    # Gmail treats barewords as separate search terms
    # subject:urgent meeting important → subject contains "urgent" AND body contains "meeting" AND "important"
    ast = GmailSearchSyntax.parse!("subject:urgent meeting important")
    assert_instance_of And, ast
    assert_equal 3, ast.operands.length

    assert_operator({name: "subject", value: "urgent"}, ast.operands[0])
    assert_string_token({value: "meeting"}, ast.operands[1])
    assert_string_token({value: "important"}, ast.operands[2])
  end

  def test_multiple_barewords_between_operators_gmail_behavior
    # Gmail treats each bareword as a separate search term
    # label:test one two three label:another → 5 terms
    ast = GmailSearchSyntax.parse!("label:test one two three label:another")
    assert_instance_of And, ast
    assert_equal 5, ast.operands.length

    assert_operator({name: "label", value: "test"}, ast.operands[0])
    assert_string_token({value: "one"}, ast.operands[1])
    assert_string_token({value: "two"}, ast.operands[2])
    assert_string_token({value: "three"}, ast.operands[3])
    assert_operator({name: "label", value: "another"}, ast.operands[4])
  end

  def test_barewords_stop_at_special_operators
    # Barewords are separate terms, OR separates two groups
    ast = GmailSearchSyntax.parse!("subject:urgent meeting OR subject:important call")
    assert_instance_of Or, ast
    assert_equal 2, ast.operands.length

    # Left side: subject:urgent AND meeting (implicit AND)
    assert_instance_of And, ast.operands[0]
    assert_equal 2, ast.operands[0].operands.length
    assert_operator({name: "subject", value: "urgent"}, ast.operands[0].operands[0])
    assert_string_token({value: "meeting"}, ast.operands[0].operands[1])

    # Right side: subject:important AND call (implicit AND)
    assert_instance_of And, ast.operands[1]
    assert_equal 2, ast.operands[1].operands.length
    assert_operator({name: "subject", value: "important"}, ast.operands[1].operands[0])
    assert_string_token({value: "call"}, ast.operands[1].operands[1])
  end

  def test_barewords_with_mixed_tokens
    # Numbers, dates, emails are all separate search terms
    ast = GmailSearchSyntax.parse!("subject:meeting 2024 Q1 review")
    assert_instance_of And, ast
    assert_equal 4, ast.operands.length

    assert_operator({name: "subject", value: "meeting"}, ast.operands[0])
    assert_string_token({value: 2024}, ast.operands[1])
    assert_string_token({value: "Q1"}, ast.operands[2])
    assert_string_token({value: "review"}, ast.operands[3])
  end

  def test_specific_gmail_example_cora_google_drive
    # label:Cora/Google Drive label:Notes
    # "Drive" is a separate search term - to include it in the label, quote it:
    # label:"Cora/Google Drive" label:Notes
    ast = GmailSearchSyntax.parse!("label:Cora/Google Drive label:Notes")
    assert_instance_of And, ast
    assert_equal 3, ast.operands.length

    # First operator: label with "Cora/Google" only
    assert_operator({name: "label", value: "Cora/Google"}, ast.operands[0])

    # "Drive" becomes a separate search term
    assert_string_token({value: "Drive"}, ast.operands[1])

    # Second operator: label with "Notes"
    assert_operator({name: "label", value: "Notes"}, ast.operands[2])
  end

  def test_label_with_consecutive_hyphens
    # Labels like "Every (Every.To)" get sanitized to "every--every.to-"
    # Gmail replaces parens, spaces, slashes with hyphens
    ast = GmailSearchSyntax.parse!("label:every--every.to-")
    assert_instance_of Operator, ast
    assert_equal "label", ast.name
    assert_equal "every--every.to-", ast.value
  end

  def test_label_with_dots_and_hyphens
    # Complex label names with dots should work
    ast = GmailSearchSyntax.parse!("label:cora-every--every.to-")
    assert_instance_of Operator, ast
    assert_equal "label", ast.name
    assert_equal "cora-every--every.to-", ast.value
  end

  def test_quoted_word_with_or_group
    # Quoted word followed by OR group in parentheses
    ast = GmailSearchSyntax.parse!('"dropbox" (file OR share OR sync OR storage OR cloud)')
    assert_instance_of And, ast
    assert_equal 2, ast.operands.length

    # First operand: quoted "dropbox" as ExactWord
    assert_instance_of ExactWord, ast.operands[0]
    assert_equal "dropbox", ast.operands[0].value

    # Second operand: OR group with 5 terms
    assert_instance_of Or, ast.operands[1]
    assert_equal 5, ast.operands[1].operands.length
    assert_equal "file", ast.operands[1].operands[0].value
    assert_equal "share", ast.operands[1].operands[1].value
    assert_equal "sync", ast.operands[1].operands[2].value
    assert_equal "storage", ast.operands[1].operands[3].value
    assert_equal "cloud", ast.operands[1].operands[4].value
  end
end
