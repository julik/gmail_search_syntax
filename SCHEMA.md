This document describes the database schema designed to support Gmail search syntax queries. The schema is optimized for the search operators defined in `lib/GMAIL_SEARCH_OPERATORS.md`.

```ruby
require 'gmail_search_syntax'

# A complex Gmail query with multiple operators
query = '(from:manager OR from:boss) subject:"quarterly review" has:attachment -label:archived after:2024/01/01 larger:5M'

ast = GmailSearchSyntax.parse!(query)
visitor = GmailSearchSyntax::SQLiteVisitor.new(current_user_email: "user@example.com")
visitor.visit(ast)

sql, params = visitor.to_query.to_sql
```

generates the following SQL:

```sql
SELECT DISTINCT m0.id 
FROM messages AS m0 
INNER JOIN message_addresses AS ma1 ON m0.id = ma1.message_id 
INNER JOIN message_addresses AS ma3 ON m0.id = ma3.message_id 
INNER JOIN message_labels AS ml ON m0.id = ml.message_id 
INNER JOIN labels AS l ON ml.label_id = l.id 
WHERE ((((ma1.address_type = ? OR ma1.address_type = ? OR ma1.address_type = ?) 
         AND ma1.email_address = ?) 
        OR ((ma3.address_type = ? OR ma3.address_type = ? OR ma3.address_type = ?) 
            AND ma3.email_address = ?)) 
       AND m0.subject LIKE ? 
       AND m0.has_attachment = 1 
       AND NOT l.name = ? 
       AND m0.internal_date > ? 
       AND m0.size_bytes > ?)
```

and bound parameters:

```
[
  "from", "cc", "bcc", "manager", "from", "cc", "bcc",
  "boss", "%quarterly review%", "archived", "2024-01-01", 5242880
]
```

## String Matching Requirements

### Prefix/Suffix Matching
Required for:
- **Email addresses** (from:, to:, cc:, bcc:, deliveredto:)
  - `from:marc@` → prefix match → `WHERE email_address LIKE 'marc@%'`
  - `from:@example.com` → suffix match → `WHERE email_address LIKE '%@example.com'`
  - `from:marc@example.com` → exact match → `WHERE email_address = 'marc@example.com'`

- **Mailing lists** (list:)
  - Same pattern as email addresses

- **Filenames** (filename:)
  - `filename:pdf` → extension match → `WHERE filename LIKE '%.pdf'`
  - `filename:homework` → prefix match → `WHERE filename LIKE 'homework%'`

### Exact Match Only
- RFC822 message IDs
- Boolean/enum fields (is:, has:, in:, category:, label:)

## SQL Visitor Usage

The library provides two SQL visitor implementations for different database backends: SQLite and Postgres. They are configured to use the schema described below. You convert the search AST nodes into a SQL query using the provided SQL visitors. If you have a different schema, use the visitor code as a template.


```ruby
ast = GmailSearchSyntax.parse!("from:amy@example.com newer_than:7d")
visitor = GmailSearchSyntax::SQLiteVisitor.new(current_user_email: "me@example.com")
visitor.visit(ast)

sql, params = visitor.to_query.to_sql
# sql: "SELECT DISTINCT m.id FROM messages m ... WHERE ... m.internal_date > datetime('now', ?)"
# params: ["from", "cc", "bcc", "amy@example.com", "-7 days"]
```

The visitors implement:

- **Parameterized queries**: All user input is bound via `?` placeholders
- **Automatic table joins**: Joins required tables based on operators
- **Nested conditions**: Properly handles AND/OR/NOT with parentheses
- **Special operators**:
  - `from:me` / `to:me` → uses `current_user_email`
  - `in:anywhere` → no location filter
  - `AROUND` → generates `(1 = 0)` no-op condition
- **Date handling**:
  - Converts dates from `YYYY/MM/DD` to `YYYY-MM-DD`
  - Parses relative times (`1y`, `2d`, `3m`) to database-specific datetime functions
- **Size parsing**: Converts `10M`, `1G` to bytes

## Fuzzy Matching Limitations

The current implementation does **not** support:
- **AROUND operator** (proximity search) - generates no-op `(1 = 0)` condition
- Full-text search with word distance calculations
- Stemming or phonetic matching
- Levenshtein distance / typo tolerance

These features require additional implementation, potentially using SQLite FTS5 extensions.

## Core Tables

```sql
-- messages
-- Primary table storing email message metadata.
CREATE TABLE messages (
    id TEXT PRIMARY KEY,
    rfc822_message_id TEXT,
    subject TEXT,
    body TEXT,
    internal_date DATETIME,
    size_bytes INTEGER,
    
    is_important BOOLEAN DEFAULT 0,
    is_starred BOOLEAN DEFAULT 0,
    is_unread BOOLEAN DEFAULT 0,
    is_read BOOLEAN DEFAULT 0,
    is_muted BOOLEAN DEFAULT 0,
    
    in_inbox BOOLEAN DEFAULT 1,
    in_archive BOOLEAN DEFAULT 0,
    in_snoozed BOOLEAN DEFAULT 0,
    in_spam BOOLEAN DEFAULT 0,
    in_trash BOOLEAN DEFAULT 0,
    
    has_attachment BOOLEAN DEFAULT 0,
    has_youtube BOOLEAN DEFAULT 0,
    has_drive BOOLEAN DEFAULT 0,
    has_document BOOLEAN DEFAULT 0,
    has_spreadsheet BOOLEAN DEFAULT 0,
    has_presentation BOOLEAN DEFAULT 0,
    
    has_yellow_star BOOLEAN DEFAULT 0,
    has_orange_star BOOLEAN DEFAULT 0,
    has_red_star BOOLEAN DEFAULT 0,
    has_purple_star BOOLEAN DEFAULT 0,
    has_blue_star BOOLEAN DEFAULT 0,
    has_green_star BOOLEAN DEFAULT 0,
    has_red_bang BOOLEAN DEFAULT 0,
    has_orange_guillemet BOOLEAN DEFAULT 0,
    has_yellow_bang BOOLEAN DEFAULT 0,
    has_green_check BOOLEAN DEFAULT 0,
    has_blue_info BOOLEAN DEFAULT 0,
    has_purple_question BOOLEAN DEFAULT 0,
    
    category TEXT,
    mailing_list TEXT,
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
`

-- message_addresses
-- Stores email addresses associated with messages (from, to, cc, bcc, delivered_to).
-- The `from:` and `to:` operators search across `from`, `cc`, and `bcc` address types per Gmail specification.

CREATE TABLE message_addresses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    message_id TEXT NOT NULL,
    address_type TEXT NOT NULL,
    email_address TEXT NOT NULL,
    display_name TEXT,
    
    FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE
);


-- labels
-- Label definitions with external string IDs.

CREATE TABLE labels (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    is_system_label BOOLEAN DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- message_labels
-- Many-to-many relationship between messages and labels.

CREATE TABLE message_labels (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    message_id TEXT NOT NULL,
    label_id TEXT NOT NULL,
    
    FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE,
    FOREIGN KEY (label_id) REFERENCES labels(id) ON DELETE CASCADE,
    UNIQUE(message_id, label_id)
);
```
-- attachments
-- File attachments associated with messages.

CREATE TABLE attachments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    message_id TEXT NOT NULL,
    filename TEXT NOT NULL,
    content_type TEXT,
    size_bytes INTEGER,
    
    FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE
);
```

