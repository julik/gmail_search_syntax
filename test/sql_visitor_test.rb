require "test_helper"

class SqlVisitorTest < Minitest::Test
  include GmailSearchSyntax::AST

  def parse_and_visit(query_string, current_user_email: nil)
    ast = GmailSearchSyntax.parse!(query_string)
    visitor = GmailSearchSyntax::SqlVisitor.new(current_user_email: current_user_email)
    visitor.visit(ast)
    visitor.to_query.to_sql
  end

  def test_simple_from_operator
    sql, params = parse_and_visit("from:amy@example.com")

    assert_includes sql, "INNER JOIN message_addresses"
    assert_includes sql, "address_type = ?"
    assert_includes sql, "email_address = ?"
    assert_equal ["from", "cc", "bcc", "amy@example.com"], params
  end

  def test_from_with_prefix_match
    sql, params = parse_and_visit("from:amy@")

    assert_includes sql, "email_address LIKE ?"
    assert_equal ["from", "cc", "bcc", "amy@%"], params
  end

  def test_from_with_suffix_match
    sql, params = parse_and_visit("from:@example.com")

    assert_includes sql, "email_address LIKE ?"
    assert_equal ["from", "cc", "bcc", "%@example.com"], params
  end

  def test_to_operator
    sql, params = parse_and_visit("to:john@example.com")

    assert_includes sql, "INNER JOIN message_addresses"
    assert_includes sql, "address_type = ?"
    assert_equal ["to", "cc", "bcc", "john@example.com"], params
  end

  def test_subject_operator
    sql, params = parse_and_visit("subject:dinner")

    assert_includes sql, "m0.subject LIKE ?"
    assert_equal ["%dinner%"], params
  end

  def test_after_date_operator
    sql, params = parse_and_visit("after:2004/04/16")

    assert_includes sql, "m0.internal_date > ?"
    assert_equal ["2004-04-16"], params
  end

  def test_before_date_operator
    sql, params = parse_and_visit("before:2004/04/18")

    assert_includes sql, "m0.internal_date < ?"
    assert_equal ["2004-04-18"], params
  end

  def test_older_than_relative
    sql, params = parse_and_visit("older_than:1y")

    assert_includes sql, "m0.internal_date < datetime('now', ?)"
    assert_equal ["-1 years"], params
  end

  def test_newer_than_relative
    sql, params = parse_and_visit("newer_than:2d")

    assert_includes sql, "m0.internal_date > datetime('now', ?)"
    assert_equal ["-2 days"], params
  end

  def test_or_operator
    sql, params = parse_and_visit("from:amy OR from:david")

    assert_includes sql, "OR"
    assert_equal ["from", "cc", "bcc", "amy", "from", "cc", "bcc", "david"], params
  end

  def test_or_operator_uses_unique_table_aliases
    sql, _params = parse_and_visit("from:alice@example.com OR from:bob@example.com")

    # Ensure we have two different aliases (ma1 and ma3, not reused)
    # This was a bug where subvisitors would reuse the same alias counter
    # (ma1 and ma3 because messages table uses fixed m0)
    assert_includes sql, "message_addresses AS ma1"
    assert_includes sql, "message_addresses AS ma3"

    # Count occurrences of each alias in the SQL
    ma1_count = sql.scan(/\bma1\b/).size
    ma3_count = sql.scan(/\bma3\b/).size

    # Each alias should appear multiple times (in JOIN and WHERE clauses)
    assert ma1_count > 1, "ma1 should appear multiple times"
    assert ma3_count > 1, "ma3 should appear multiple times"
  end

  def test_and_operator
    sql, params = parse_and_visit("from:amy AND to:david")

    assert_includes sql, "AND"
    assert_equal ["from", "cc", "bcc", "amy", "to", "cc", "bcc", "david"], params
  end

  def test_implicit_and
    sql, params = parse_and_visit("from:amy to:david")

    assert_includes sql, "AND"
    assert_equal ["from", "cc", "bcc", "amy", "to", "cc", "bcc", "david"], params
  end

  def test_negation
    sql, _ = parse_and_visit("dinner -movie")

    assert_includes sql, "NOT"
    assert_includes sql, "m0.subject LIKE ?"
    assert_includes sql, "m0.body LIKE ?"
  end

  def test_label_operator
    sql, params = parse_and_visit("label:friends")

    assert_includes sql, "INNER JOIN message_labels"
    assert_includes sql, "INNER JOIN labels"
    assert_includes sql, "name = ?"
    assert_equal ["friends"], params
  end

  def test_category_operator
    sql, params = parse_and_visit("category:primary")

    assert_includes sql, "m0.category = ?"
    assert_equal ["primary"], params
  end

  def test_has_attachment
    sql, params = parse_and_visit("has:attachment")

    assert_includes sql, "m0.has_attachment = 1"
    assert_equal [], params
  end

  def test_has_yellow_star
    sql, params = parse_and_visit('has:"yellow-star"')

    assert_includes sql, "m0.has_yellow_star = 1"
    assert_equal [], params
  end

  def test_has_userlabels
    sql, params = parse_and_visit("has:userlabels")

    assert_includes sql, "INNER JOIN message_labels"
    assert_includes sql, "is_system_label = 0"
    assert_equal [], params
  end

  def test_has_nouserlabels
    sql, params = parse_and_visit("has:nouserlabels")

    assert_includes sql, "NOT EXISTS"
    assert_includes sql, "is_system_label = 0"
    assert_equal [], params
  end

  def test_filename_extension
    sql, params = parse_and_visit("filename:pdf")

    assert_includes sql, "INNER JOIN attachments"
    assert_includes sql, "filename LIKE ?"
    assert_equal ["%.pdf", "pdf%"], params
  end

  def test_filename_exact
    sql, params = parse_and_visit("filename:homework.txt")

    assert_includes sql, "INNER JOIN attachments"
    assert_includes sql, "filename = ?"
    assert_equal ["homework.txt"], params
  end

  def test_in_inbox
    sql, params = parse_and_visit("in:inbox")

    assert_includes sql, "m0.in_inbox = 1"
    assert_equal [], params
  end

  def test_in_anywhere
    sql, _ = parse_and_visit("in:anywhere")

    refute_includes sql, "in_inbox"
    refute_includes sql, "in_archive"
  end

  def test_is_starred
    sql, params = parse_and_visit("is:starred")

    assert_includes sql, "m0.is_starred = 1"
    assert_equal [], params
  end

  def test_is_unread
    sql, params = parse_and_visit("is:unread")

    assert_includes sql, "m0.is_unread = 1"
    assert_equal [], params
  end

  def test_size_operator
    sql, params = parse_and_visit("size:1000000")

    assert_includes sql, "m0.size_bytes = ?"
    assert_equal [1000000], params
  end

  def test_larger_operator_with_m_suffix
    sql, params = parse_and_visit("larger:10M")

    assert_includes sql, "m0.size_bytes > ?"
    assert_equal [10 * 1024 * 1024], params
  end

  def test_smaller_operator
    sql, params = parse_and_visit("smaller:1M")

    assert_includes sql, "m0.size_bytes < ?"
    assert_equal [1 * 1024 * 1024], params
  end

  def test_rfc822msgid_operator
    sql, params = parse_and_visit("rfc822msgid:200503292@example.com")

    assert_includes sql, "m0.rfc822_message_id = ?"
    assert_equal ["200503292@example.com"], params
  end

  def test_plain_text_search
    sql, params = parse_and_visit("meeting")

    # Text nodes now use word boundary matching
    assert_includes sql, "m0.subject = ?"
    assert_includes sql, "m0.subject LIKE ?"
    assert_includes sql, "m0.body = ?"
    assert_includes sql, "m0.body LIKE ?"
    assert_equal ["meeting", "meeting %", "% meeting", "% meeting %", "meeting", "meeting %", "% meeting", "% meeting %"], params
  end

  def test_quoted_text_search_uses_substring
    sql, params = parse_and_visit('"meeting"')

    # Quoted strings create ExactWord nodes which use LIKE %value%
    assert_includes sql, "m0.subject LIKE ?"
    assert_includes sql, "m0.body LIKE ?"
    assert_equal ["%meeting%", "%meeting%"], params
  end

  def test_complex_query
    sql, _ = parse_and_visit("from:amy subject:meeting has:attachment")

    assert_includes sql, "AND"
    assert_includes sql, "INNER JOIN message_addresses"
    assert_includes sql, "m0.subject LIKE ?"
    assert_includes sql, "m0.has_attachment = 1"
  end

  def test_or_with_parentheses
    sql, _ = parse_and_visit("from:(amy@example.com OR bob@example.com)")

    assert_includes sql, "OR"
    assert_includes sql, "INNER JOIN message_addresses"
  end

  def test_braces_as_or
    sql, _ = parse_and_visit("from:{amy@example.com bob@example.com}")

    assert_includes sql, "OR"
  end

  def test_negation_with_operator
    sql, params = parse_and_visit("-from:spam@example.com")

    assert_includes sql, "NOT"
    assert_includes sql, "INNER JOIN message_addresses"
    assert_equal ["from", "cc", "bcc", "spam@example.com"], params
  end

  def test_around_operator_generates_noop
    sql, params = parse_and_visit("holiday AROUND 10 vacation")

    assert_includes sql, "(1 = 0)"
    assert_equal [], params
  end

  def test_list_operator
    sql, params = parse_and_visit("list:info@example.com")

    assert_includes sql, "m0.mailing_list = ?"
    assert_equal ["info@example.com"], params
  end

  def test_list_with_suffix_match
    sql, params = parse_and_visit("list:@example.com")

    assert_includes sql, "m0.mailing_list LIKE ?"
    assert_equal ["%@example.com"], params
  end

  def test_deliveredto_operator
    sql, params = parse_and_visit("deliveredto:username@example.com")

    assert_includes sql, "INNER JOIN message_addresses"
    assert_includes sql, "address_type = ?"
    assert_equal ["delivered_to", "username@example.com"], params
  end

  def test_cc_operator
    sql, params = parse_and_visit("cc:john@example.com")

    assert_includes sql, "address_type = ?"
    assert_equal ["cc", "john@example.com"], params
  end

  def test_bcc_operator
    sql, params = parse_and_visit("bcc:david@example.com")

    assert_includes sql, "address_type = ?"
    assert_equal ["bcc", "david@example.com"], params
  end

  def test_from_me_with_current_user
    sql, params = parse_and_visit("from:me", current_user_email: "test@example.com")

    assert_includes sql, "email_address = ?"
    assert_equal ["from", "cc", "bcc", "test@example.com"], params
  end

  def test_nested_conditions
    sql, _ = parse_and_visit("from:amy (subject:meeting OR subject:call)")

    assert_includes sql, "AND"
    assert_includes sql, "OR"
    assert_includes sql, "m0.subject LIKE ?"
  end

  def test_multiple_joins_with_same_table
    sql, _ = parse_and_visit("from:amy to:bob")

    join_count = sql.scan("INNER JOIN message_addresses").length
    assert_equal 2, join_count
  end

  def test_quoted_string_with_escaped_quotes
    sql, params = parse_and_visit('"She said \\"hello\\" to me"')

    assert_includes sql, "m0.subject LIKE ?"
    assert_includes sql, "m0.body LIKE ?"
    assert_equal ['%She said "hello" to me%', '%She said "hello" to me%'], params
  end

  def test_subject_with_escaped_quotes
    sql, params = parse_and_visit('subject:"Meeting: \\"Q1 Review\\""')

    assert_includes sql, "m0.subject LIKE ?"
    assert_equal ['%Meeting: "Q1 Review"%'], params
  end

  def test_unquoted_token_with_escaped_quote
    sql, params = parse_and_visit('meeting\\"room')

    # Unquoted tokens use word boundary matching
    assert_includes sql, "m0.subject = ?"
    assert_includes sql, "m0.body = ?"
    assert_equal ['meeting"room', 'meeting"room %', '% meeting"room', '% meeting"room %', 'meeting"room', 'meeting"room %', '% meeting"room', '% meeting"room %'], params
  end

  def test_operator_with_unquoted_escaped_quote
    sql, params = parse_and_visit('subject:test\\"value')

    assert_includes sql, "m0.subject LIKE ?"
    assert_equal ['%test"value%'], params
  end
end
