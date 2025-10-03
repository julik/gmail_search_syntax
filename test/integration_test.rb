require "test_helper"
require "sqlite3"
require "yaml"

class IntegrationTest < Minitest::Test
  def setup
    @db = SQLite3::Database.new(":memory:")
    create_tables
    seed_labels
    seed_messages
  end

  def teardown
    @db&.close
  end

  def debug(message)
    puts message if ENV["DEBUG"]
  end

  def create_tables
    @db.execute_batch <<-SQL
      CREATE TABLE messages (
          id TEXT PRIMARY KEY,
          rfc822_message_id TEXT,
          subject TEXT,
          body TEXT,
          internal_date DATETIME,
          size_bytes INTEGER,
          
          is_important INTEGER DEFAULT 0,
          is_starred INTEGER DEFAULT 0,
          is_unread INTEGER DEFAULT 0,
          is_read INTEGER DEFAULT 0,
          is_muted INTEGER DEFAULT 0,
          
          in_inbox INTEGER DEFAULT 1,
          in_archive INTEGER DEFAULT 0,
          in_snoozed INTEGER DEFAULT 0,
          in_spam INTEGER DEFAULT 0,
          in_trash INTEGER DEFAULT 0,
          
          has_attachment INTEGER DEFAULT 0,
          has_youtube INTEGER DEFAULT 0,
          has_drive INTEGER DEFAULT 0,
          has_document INTEGER DEFAULT 0,
          has_spreadsheet INTEGER DEFAULT 0,
          has_presentation INTEGER DEFAULT 0,
          
          has_yellow_star INTEGER DEFAULT 0,
          has_orange_star INTEGER DEFAULT 0,
          has_red_star INTEGER DEFAULT 0,
          has_purple_star INTEGER DEFAULT 0,
          has_blue_star INTEGER DEFAULT 0,
          has_green_star INTEGER DEFAULT 0,
          has_red_bang INTEGER DEFAULT 0,
          has_orange_guillemet INTEGER DEFAULT 0,
          has_yellow_bang INTEGER DEFAULT 0,
          has_green_check INTEGER DEFAULT 0,
          has_blue_info INTEGER DEFAULT 0,
          has_purple_question INTEGER DEFAULT 0,
          
          category TEXT,
          mailing_list TEXT,
          
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX idx_messages_internal_date ON messages(internal_date);
      CREATE INDEX idx_messages_size_bytes ON messages(size_bytes);
      CREATE INDEX idx_messages_rfc822_message_id ON messages(rfc822_message_id);
      CREATE INDEX idx_messages_category ON messages(category);
      CREATE INDEX idx_messages_mailing_list ON messages(mailing_list);

      CREATE TABLE message_addresses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          message_id TEXT NOT NULL,
          address_type TEXT NOT NULL,
          email_address TEXT NOT NULL,
          display_name TEXT,
          
          FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE
      );

      CREATE INDEX idx_message_addresses_message_id ON message_addresses(message_id);
      CREATE INDEX idx_message_addresses_email ON message_addresses(email_address);
      CREATE INDEX idx_message_addresses_type_email ON message_addresses(address_type, email_address);

      CREATE TABLE labels (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL UNIQUE,
          is_system_label INTEGER DEFAULT 0,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX idx_labels_name ON labels(name);

      CREATE TABLE message_labels (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          message_id TEXT NOT NULL,
          label_id TEXT NOT NULL,
          
          FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE,
          FOREIGN KEY (label_id) REFERENCES labels(id) ON DELETE CASCADE,
          UNIQUE(message_id, label_id)
      );

      CREATE INDEX idx_message_labels_message_id ON message_labels(message_id);
      CREATE INDEX idx_message_labels_label_id ON message_labels(label_id);
      CREATE INDEX idx_message_labels_both ON message_labels(message_id, label_id);

      CREATE TABLE attachments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          message_id TEXT NOT NULL,
          filename TEXT NOT NULL,
          content_type TEXT,
          size_bytes INTEGER,
          
          FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE
      );

      CREATE INDEX idx_attachments_message_id ON attachments(message_id);
      CREATE INDEX idx_attachments_filename ON attachments(filename);
    SQL
  end

  def seed_labels
    labels_yaml = <<~YAML
      ---
      - id: CHAT
        label_list_visibility: labelShow
        message_list_visibility: hide
        name: CHAT
        type: system
      - id: SENT
        name: SENT
        type: system
      - id: INBOX
        label_list_visibility: labelShow
        message_list_visibility: hide
        name: INBOX
        type: system
      - id: IMPORTANT
        label_list_visibility: labelShow
        message_list_visibility: hide
        name: IMPORTANT
        type: system
      - id: TRASH
        label_list_visibility: labelShow
        message_list_visibility: hide
        name: TRASH
        type: system
      - id: DRAFT
        name: DRAFT
        type: system
      - id: SPAM
        label_list_visibility: labelShow
        message_list_visibility: hide
        name: SPAM
        type: system
      - id: CATEGORY_FORUMS
        name: CATEGORY_FORUMS
        type: system
      - id: CATEGORY_UPDATES
        name: CATEGORY_UPDATES
        type: system
      - id: CATEGORY_PERSONAL
        name: CATEGORY_PERSONAL
        type: system
      - id: CATEGORY_PROMOTIONS
        name: CATEGORY_PROMOTIONS
        type: system
      - id: CATEGORY_SOCIAL
        name: CATEGORY_SOCIAL
        type: system
      - id: STARRED
        name: STARRED
        type: system
      - id: UNREAD
        name: UNREAD
        type: system
      - color:
          background_color: "#c9daf8"
          text_color: "#285bac"
        id: Label_10
        label_list_visibility: labelShow
        message_list_visibility: hide
        name: "📥 Next Brief"
        type: user
      - color:
          background_color: "#ffe6c7"
          text_color: "#a46a21"
        id: Label_11
        label_list_visibility: labelShow
        message_list_visibility: hide
        name: "✉️ All Briefs"
        type: user
      - id: Label_12
        label_list_visibility: labelShow
        message_list_visibility: hide
        name: Cora
        type: user
      - id: Label_13
        label_list_visibility: labelShow
        message_list_visibility: hide
        name: Cora/Other
        type: user
      - id: Label_14
        label_list_visibility: labelShow
        message_list_visibility: hide
        name: Cora/Newsletter
        type: user
      - id: Label_15
        label_list_visibility: labelShow
        message_list_visibility: hide
        name: Cora/Action
        type: user
      - id: Label_16
        label_list_visibility: labelShow
        message_list_visibility: hide
        name: Cora/Promotion
        type: user
      - id: Label_17
        label_list_visibility: labelShow
        message_list_visibility: hide
        name: Cora/Every (Every.To)
        type: user
      - id: Label_18
        label_list_visibility: labelShow
        message_list_visibility: hide
        name: Cora/Important Info
        type: user
      - id: Label_19
        label_list_visibility: labelShow
        message_list_visibility: hide
        name: Cora/Google Drive
        type: user
      - id: Label_2
        name: Apple Mail To Do
        type: user
      - id: Label_4
        label_list_visibility: labelShow
        message_list_visibility: hide
        name: Drafts (gmail)
        type: user
      - id: Label_5
        label_list_visibility: labelShow
        message_list_visibility: hide
        name: Junk (gmail)
        type: user
      - id: Label_6
        name: Notes
        type: user
      - id: Label_8
        name: Sent Messages (gmail)
        type: user
      - id: Label_9
        name: ror
        type: user
    YAML

    labels = YAML.load(labels_yaml)

    labels.each do |label|
      is_system = (label["type"] == "system") ? 1 : 0
      @db.execute(
        "INSERT INTO labels (id, name, is_system_label) VALUES (?, ?, ?)",
        [label["id"], label["name"], is_system]
      )
    end
  end

  def seed_messages
    senders = [
      "alice@example.com", "bob@example.com", "charlie@example.com",
      "david@company.com", "eve@startup.io", "frank@business.net",
      "grace@tech.com", "heidi@design.co", "ivan@marketing.com",
      "judy@sales.com"
    ]

    recipients = [
      "me@example.com", "team@example.com", "support@example.com",
      "info@example.com", "admin@example.com"
    ]

    subjects = [
      "Meeting tomorrow", "Quarterly report", "Project update",
      "Quick question", "Follow up", "Important announcement",
      "Weekly newsletter", "Invitation to event", "Budget proposal",
      "Code review needed"
    ]

    categories = ["primary", "social", "promotions", "updates", "forums", nil]

    mailing_lists = [
      "announcements@example.com", "dev-team@company.com",
      "newsletter@startup.io", nil, nil, nil
    ]

    attachment_names = [
      "report.pdf", "presentation.pptx", "spreadsheet.xlsx",
      "document.docx", "image.jpg", "archive.zip"
    ]

    label_ids = @db.execute("SELECT id FROM labels WHERE is_system_label = 0").flatten

    two_years_ago = Time.now - (2 * 365 * 24 * 60 * 60)
    now = Time.now

    100.times do |i|
      message_id = "msg_#{i}_#{rand(1000000)}"
      rfc822_id = "#{rand(1000000)}@example.com"

      internal_date = Time.at(rand(two_years_ago.to_i..now.to_i))

      subject = subjects.sample + " ##{i}"
      body = "This is the body of message #{i}. " + ("Lorem ipsum dolor sit amet. " * 10)

      size_bytes = rand(1024..10485760)

      category = categories.sample
      mailing_list = mailing_lists.sample

      @db.execute(
        <<-SQL,
        INSERT INTO messages (
          id, rfc822_message_id, subject, body, internal_date, size_bytes,
          is_important, is_starred, is_unread, is_read, is_muted,
          in_inbox, in_archive, in_snoozed, in_spam, in_trash,
          has_attachment, has_youtube, has_drive, has_document, has_spreadsheet, has_presentation,
          has_yellow_star, has_orange_star, has_red_star, has_purple_star, has_blue_star, has_green_star,
          has_red_bang, has_orange_guillemet, has_yellow_bang, has_green_check, has_blue_info, has_purple_question,
          category, mailing_list
        ) VALUES (
          ?, ?, ?, ?, ?, ?,
          ?, ?, ?, ?, ?,
          ?, ?, ?, ?, ?,
          ?, ?, ?, ?, ?, ?,
          ?, ?, ?, ?, ?, ?,
          ?, ?, ?, ?, ?, ?,
          ?, ?
        )
        SQL
        [message_id, rfc822_id, subject, body,
          internal_date.strftime("%Y-%m-%d %H:%M:%S"), size_bytes,
          rand(2), rand(2), rand(2), rand(2), rand(2),
          rand(2), rand(2), rand(2), rand(2), rand(2),
          rand(2), rand(2), rand(2), rand(2), rand(2), rand(2),
          rand(2), rand(2), rand(2), rand(2), rand(2), rand(2),
          rand(2), rand(2), rand(2), rand(2), rand(2),
          category, mailing_list]
      )

      sender = senders.sample
      @db.execute(
        "INSERT INTO message_addresses (message_id, address_type, email_address) VALUES (?, ?, ?)",
        [message_id, "from", sender]
      )

      rand(1..3).times do
        recipient = recipients.sample
        address_type = ["to", "cc"].sample
        @db.execute(
          "INSERT INTO message_addresses (message_id, address_type, email_address) VALUES (?, ?, ?)",
          [message_id, address_type, recipient]
        )
      end

      rand(0..3).times do
        label_id = label_ids.sample
        begin
          @db.execute(
            "INSERT INTO message_labels (message_id, label_id) VALUES (?, ?)",
            [message_id, label_id]
          )
        rescue SQLite3::ConstraintException
        end
      end

      if rand < 0.3
        rand(1..2).times do
          filename = attachment_names.sample
          @db.execute(
            "INSERT INTO attachments (message_id, filename, content_type, size_bytes) VALUES (?, ?, ?, ?)",
            [message_id, filename, "application/octet-stream", rand(1024..5242880)]
          )
        end
      end
    end
  end

  def test_database_setup_successful
    message_count = @db.get_first_value("SELECT COUNT(*) FROM messages")
    assert_equal 100, message_count

    label_count = @db.get_first_value("SELECT COUNT(*) FROM labels")
    assert_equal 30, label_count

    address_count = @db.get_first_value("SELECT COUNT(*) FROM message_addresses")
    assert message_count > 0

    debug "\nDatabase seeded successfully:"
    debug "  Messages: #{message_count}"
    debug "  Labels: #{label_count}"
    debug "  Addresses: #{address_count}"
    debug "  Attachments: #{@db.get_first_value("SELECT COUNT(*) FROM attachments")}"
    debug "  Message-Label associations: #{@db.get_first_value("SELECT COUNT(*) FROM message_labels")}"
  end

  def test_query_5_latest_messages
    rows = @db.execute(<<-SQL)
      SELECT m.id, m.subject, m.internal_date
      FROM messages m
      ORDER BY m.internal_date DESC
      LIMIT 5
    SQL

    assert_equal 5, rows.length

    debug "\n5 Latest messages:"
    rows.each do |row|
      debug "  #{row[0]}: #{row[1]} (#{row[2]})"
    end

    dates = rows.map { |r| r[2] }
    assert_equal dates.sort.reverse, dates, "Messages should be ordered by date DESC"
  end

  def test_query_with_from_operator
    ast = GmailSearchSyntax.parse!("from:alice@example.com")
    visitor = GmailSearchSyntax::SqlVisitor.new
    visitor.visit(ast)

    sql, params = visitor.to_query.to_sql

    rows = @db.execute(sql, params)

    assert rows.length > 0, "Should find messages from alice@example.com"

    rows.each do |row|
      message_id = row[0]
      addresses = @db.execute(
        "SELECT email_address FROM message_addresses WHERE message_id = ? AND address_type = 'from'",
        [message_id]
      )
      assert addresses.any? { |addr| addr[0] == "alice@example.com" },
        "Message #{message_id} should have alice@example.com as sender"
    end

    debug "\nFound #{rows.length} messages from alice@example.com"
  end

  def test_query_with_subject_operator
    ast = GmailSearchSyntax.parse!("subject:meeting")
    visitor = GmailSearchSyntax::SqlVisitor.new
    visitor.visit(ast)

    sql, params = visitor.to_query.to_sql

    rows = @db.execute(sql, params)

    assert rows.length > 0, "Should find messages with 'meeting' in subject"

    rows.each do |row|
      message_id = row[0]
      subject = @db.get_first_value("SELECT subject FROM messages WHERE id = ?", [message_id])
      assert subject.downcase.include?("meeting"),
        "Message #{message_id} subject '#{subject}' should contain 'meeting'"
    end

    debug "\nFound #{rows.length} messages with 'meeting' in subject"
  end

  def test_query_with_has_attachment
    ast = GmailSearchSyntax.parse!("has:attachment")
    visitor = GmailSearchSyntax::SqlVisitor.new
    visitor.visit(ast)

    sql, params = visitor.to_query.to_sql

    rows = @db.execute(sql, params)

    assert rows.length > 0, "Should find messages with attachments"

    rows.each do |row|
      message_id = row[0]
      has_attachment = @db.get_first_value(
        "SELECT has_attachment FROM messages WHERE id = ?",
        [message_id]
      )
      assert_equal 1, has_attachment, "Message #{message_id} should have has_attachment = 1"
    end

    debug "\nFound #{rows.length} messages with attachments"
  end

  def test_query_with_complex_conditions
    ast = GmailSearchSyntax.parse!("from:alice@example.com subject:meeting")
    visitor = GmailSearchSyntax::SqlVisitor.new
    visitor.visit(ast)

    sql, params = visitor.to_query.to_sql

    rows = @db.execute(sql, params)

    rows.each do |row|
      message_id = row[0]

      addresses = @db.execute(
        "SELECT email_address FROM message_addresses WHERE message_id = ? AND address_type IN ('from', 'cc', 'bcc')",
        [message_id]
      )
      assert addresses.any? { |addr| addr[0] == "alice@example.com" },
        "Message #{message_id} should have alice@example.com in from/cc/bcc"

      subject = @db.get_first_value("SELECT subject FROM messages WHERE id = ?", [message_id])
      assert subject.downcase.include?("meeting"),
        "Message #{message_id} subject '#{subject}' should contain 'meeting'"
    end

    debug "\nFound #{rows.length} messages from alice@example.com with 'meeting' in subject"
  end

  def test_query_with_label
    label_name = "Cora"

    label_exists = @db.get_first_value("SELECT COUNT(*) FROM labels WHERE name = ?", [label_name])
    assert label_exists > 0, "Label '#{label_name}' should exist"

    ast = GmailSearchSyntax.parse!("label:Cora")
    visitor = GmailSearchSyntax::SqlVisitor.new
    visitor.visit(ast)

    sql, params = visitor.to_query.to_sql

    rows = @db.execute(sql, params)

    rows.each do |row|
      message_id = row[0]

      labels = @db.execute(
        "SELECT l.name FROM message_labels ml " \
        "INNER JOIN labels l ON ml.label_id = l.id " \
        "WHERE ml.message_id = ?",
        [message_id]
      )
      label_names = labels.map { |l| l[0] }
      assert label_names.include?("Cora"),
        "Message #{message_id} should have label 'Cora', has: #{label_names.inspect}"
    end

    debug "\nFound #{rows.length} messages with label 'Cora'"
  end

  def test_query_with_date_range
    one_year_ago = (Time.now - 365 * 24 * 60 * 60).strftime("%Y/%m/%d")
    one_year_ago_time = Time.parse(one_year_ago)

    ast = GmailSearchSyntax.parse!("after:#{one_year_ago}")
    visitor = GmailSearchSyntax::SqlVisitor.new
    visitor.visit(ast)

    sql, params = visitor.to_query.to_sql

    rows = @db.execute(sql, params)

    assert rows.length > 0, "Should find messages from the last year"

    rows.each do |row|
      message_id = row[0]
      internal_date_str = @db.get_first_value(
        "SELECT internal_date FROM messages WHERE id = ?",
        [message_id]
      )
      internal_date = Time.parse(internal_date_str)
      assert internal_date > one_year_ago_time,
        "Message #{message_id} date #{internal_date} should be after #{one_year_ago_time}"
    end

    debug "\nFound #{rows.length} messages after #{one_year_ago}"
  end

  def test_query_with_size_filter
    ast = GmailSearchSyntax.parse!("larger:1M")
    visitor = GmailSearchSyntax::SqlVisitor.new
    visitor.visit(ast)

    sql, params = visitor.to_query.to_sql

    rows = @db.execute(sql, params)

    rows.each do |row|
      message_id = row[0]
      size = @db.get_first_value("SELECT size_bytes FROM messages WHERE id = ?", [message_id])
      assert size > 1048576, "Message #{message_id} should be larger than 1M"
    end

    debug "\nFound #{rows.length} messages larger than 1M"
  end
end
