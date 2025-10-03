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

