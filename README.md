# gmail_search_syntax

Parser for Gmail's search syntax. Converts Gmail search queries into an Abstract Syntax Tree.

Based on the official Gmail search operators documentation:  
https://support.google.com/mail/answer/7190

> [!TIP]
> This gem was created for [Cora,](https://cora.computer/) your personal e-mail assistant. 
> Send them some love for allowing me to share it.

## Installation

```ruby
gem 'gmail_search_syntax'
```

## Usage

```ruby
require 'gmail_search_syntax'

ast = GmailSearchSyntax.parse!("from:boss subject:meeting")
# => #<And #<Operator from: "boss"> AND #<Operator subject: "meeting">>
```

Afterwards you can do all sorts of interesting things with this, for example - transform your AST nodes into Elastic or SQL queries, or execute them bottom-op just from arrays in memory.

### Examples

```ruby
# Simple operator
GmailSearchSyntax.parse!("from:amy@example.com")
# => #<Operator from: "amy@example.com">

# Logical OR
GmailSearchSyntax.parse!("from:amy OR from:bob")
# => #<Or #<Operator from: "amy"> OR #<Operator from: "bob">>

# Negation
GmailSearchSyntax.parse!("dinner -movie")
# => #<And #<Text "dinner"> AND #<Not #<Text "movie">>>

# Proximity search
GmailSearchSyntax.parse!("holiday AROUND 10 vacation")
# => #<Around #<Text "holiday"> AROUND 10 #<Text "vacation">>

# Complex query with OR inside operator values
GmailSearchSyntax.parse!("from:{alice@ bob@} subject:urgent")
# => #<And #<Operator from: #<Or ...>> AND #<Operator subject: "urgent">>

# Empty queries raise an error
GmailSearchSyntax.parse!("")
# => raises GmailSearchSyntax::EmptyQueryError
```

### Converting to SQL

The gem includes a SQLite visitor that can convert Gmail queries to SQL. Here's a complex example:

```ruby
require 'gmail_search_syntax'

# A complex Gmail query with multiple operators
query = '(from:manager OR from:boss) subject:"quarterly review" has:attachment -label:archived after:2024/01/01 larger:5M'

ast = GmailSearchSyntax.parse!(query)
visitor = GmailSearchSyntax::SQLiteVisitor.new(current_user_email: "user@example.com")
visitor.visit(ast)

sql, params = visitor.to_query.to_sql
```

This generates the following SQL:

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

With parameters: `["from", "cc", "bcc", "manager", "from", "cc", "bcc", "boss", "%quarterly review%", "archived", "2024-01-01", 5242880]`

A similar visitor is provided for PostgreSQL.

## Supported Operators

Email routing: `from:`, `to:`, `cc:`, `bcc:`, `deliveredto:`  
Metadata: `subject:`, `label:`, `category:`, `list:`  
Dates: `after:`, `before:`, `older:`, `newer:`, `older_than:`, `newer_than:`  
Attachments: `has:`, `filename:`  
Status: `is:`, `in:`  
Size: `size:`, `larger:`, `smaller:`

## Features

- Handles operator precedence (negation, AROUND, implicit AND, explicit AND, OR)
- Supports grouping with parentheses and braces
- Recognizes emails, dates, quoted strings, and numbers
- Minimal AST structure

There is also a converter from the operators to SQL queries against an embedded SQLite database. This is meant more as an example than a fully-featured store, but it shows what's possible.

## Testing

```bash
bundle exec rake test
```

## License

MIT

## Legal Notes

Gmail is a trademark of Google LLC.

