require_relative "test_helper"

class PostgresVisitorTest < Minitest::Test
  def parse_and_visit(query, current_user_email: nil)
    ast = GmailSearchSyntax.parse!(query)
    visitor = GmailSearchSyntax::PostgresVisitor.new(current_user_email: current_user_email)
    visitor.visit(ast)
    visitor.to_query.to_sql
  end

  def test_from_operator
    sql, params = parse_and_visit("from:alice@example.com")

    assert_includes sql, "INNER JOIN message_addresses"
    assert_includes sql, "ma1.address_type = ?"
    assert_includes sql, "ma1.email_address = ?"
    assert_equal ["from", "cc", "bcc", "alice@example.com"], params
  end

  def test_subject_operator
    sql, params = parse_and_visit("subject:meeting")

    assert_includes sql, "m.subject LIKE ?"
    assert_equal ["%meeting%"], params
  end

  def test_older_than_relative_postgres_syntax
    sql, params = parse_and_visit("older_than:1y")

    assert_includes sql, "m.internal_date < (NOW() - ?::interval)"
    assert_equal ["1 years"], params
  end

  def test_newer_than_relative_postgres_syntax
    sql, params = parse_and_visit("newer_than:2d")

    assert_includes sql, "m.internal_date > (NOW() - ?::interval)"
    assert_equal ["2 days"], params
  end

  def test_older_than_7_days_postgres
    sql, params = parse_and_visit("older_than:7d")

    assert_includes sql, "m.internal_date < (NOW() - ?::interval)"
    assert_equal ["7 days"], params
  end

  def test_newer_than_3_months_postgres
    sql, params = parse_and_visit("newer_than:3m")

    assert_includes sql, "m.internal_date > (NOW() - ?::interval)"
    assert_equal ["3 months"], params
  end

  def test_older_than_2_years_postgres
    sql, params = parse_and_visit("older_than:2y")

    assert_includes sql, "m.internal_date < (NOW() - ?::interval)"
    assert_equal ["2 years"], params
  end

  def test_or_operator
    sql, params = parse_and_visit("from:alice@example.com OR from:bob@example.com")

    assert_includes sql, "OR"
    assert_includes sql, ".email_address = ?"
    assert_equal ["from", "cc", "bcc", "alice@example.com", "from", "cc", "bcc", "bob@example.com"], params
  end

  def test_and_operator
    sql, params = parse_and_visit("from:alice@example.com AND subject:meeting")

    assert_includes sql, "AND"
    assert_includes sql, "ma1.email_address = ?"
    assert_includes sql, "m.subject LIKE ?"
    assert_equal ["from", "cc", "bcc", "alice@example.com", "%meeting%"], params
  end

  def test_not_operator
    sql, params = parse_and_visit("-from:spam@example.com")

    assert_includes sql, "NOT"
    assert_includes sql, "ma1.email_address = ?"
    assert_equal ["from", "cc", "bcc", "spam@example.com"], params
  end

  def test_complex_query
    sql, params = parse_and_visit("from:alice@example.com subject:meeting has:attachment")

    assert_includes sql, "ma1.email_address = ?"
    assert_includes sql, "m.subject LIKE ?"
    assert_includes sql, "m.has_attachment = 1"
    assert_equal ["from", "cc", "bcc", "alice@example.com", "%meeting%"], params
  end

  def test_label_operator
    sql, params = parse_and_visit("label:important")

    assert_includes sql, "INNER JOIN message_labels"
    assert_includes sql, "INNER JOIN labels"
    assert_includes sql, ".name = ?"
    assert_equal ["important"], params
  end

  def test_is_starred
    sql, params = parse_and_visit("is:starred")

    assert_includes sql, "m.is_starred = 1"
    assert_equal [], params
  end

  def test_has_attachment
    sql, params = parse_and_visit("has:attachment")

    assert_includes sql, "m.has_attachment = 1"
    assert_equal [], params
  end

  def test_larger_operator
    sql, params = parse_and_visit("larger:10M")

    assert_includes sql, "m.size_bytes > ?"
    assert_equal [10 * 1024 * 1024], params
  end

  def test_filename_operator
    sql, params = parse_and_visit("filename:report.pdf")

    assert_includes sql, "INNER JOIN attachments"
    assert_includes sql, ".filename = ?"
    assert_equal ["report.pdf"], params
  end

  def test_backward_compatibility_with_older_than_and_newer_than
    # Test that we properly inherit all other behavior from SQLiteVisitor
    sql1, params1 = parse_and_visit("from:alice@example.com")

    ast = GmailSearchSyntax.parse!("from:alice@example.com")
    sqlite_visitor = GmailSearchSyntax::SQLiteVisitor.new
    sqlite_visitor.visit(ast)
    sql2, params2 = sqlite_visitor.to_query.to_sql

    # Structure should be the same (just the relative date handling differs)
    assert_equal params1, params2
    # The SQL should be identical for non-date queries
    assert_equal sql1, sql2
  end

  def test_combined_relative_dates_and_other_operators
    sql, params = parse_and_visit("from:alice@example.com newer_than:7d")

    assert_includes sql, "ma1.email_address = ?"
    assert_includes sql, "m.internal_date > (NOW() - ?::interval)"
    assert_equal ["from", "cc", "bcc", "alice@example.com", "7 days"], params
  end
end
