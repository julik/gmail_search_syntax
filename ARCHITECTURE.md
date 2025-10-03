# Gmail Search Syntax Parser Architecture

A rigorous parser for Gmail's search syntax as documented at [Gmail Help](https://support.google.com/mail/answer/7190).

## Architecture Overview

The parser is built in three stages:

1. **Tokenization** - Breaking the input string into tokens
2. **Parsing** - Building an Abstract Syntax Tree (AST) from tokens
3. **AST** - Minimal tree structure representing the search query

## Tokenization

The `Tokenizer` class scans the input character by character and produces a stream of tokens.

### Token Types

- **Keywords**: `word` - Operator names (from, to, subject, etc.)
- **Punctuation**: `colon`, `lparen`, `rparen`, `lbrace`, `rbrace`, `minus`, `plus`
- **Logical Operators**: `or`, `and`, `around`
- **Values**: `email`, `number`, `date`, `relative_time`, `quoted_string`
- **End**: `eof`

### Key Features

- Recognizes email addresses (contains `@`)
- Parses quoted strings with escape sequences
- Identifies dates (`YYYY/MM/DD` or `MM/DD/YYYY`)
- Recognizes relative times (`1y`, `2d`, `3m`)
- Handles logical operators (`OR`, `AND`, `AROUND`)
- Properly tokenizes negation (`-`)

### Example

```ruby
Input:  'from:amy@example.com subject:"meeting notes"'
Tokens: [word("from"), colon, email("amy@example.com"), 
         word("subject"), colon, quoted_string("meeting notes"), eof]
```

## Parsing

The `Parser` class implements a recursive descent parser that builds an AST from the token stream.

### Operator Precedence (highest to lowest)

1. Unary operators (`-`, `+`)
2. Primary expressions (operators, text, grouping)
3. `AROUND` (proximity search)
4. Implicit `AND` (adjacency)
5. Explicit `AND`
6. `OR`

### Grammar

```
expression       → or_expression
or_expression    → and_expression ( "OR" and_expression )*
and_expression   → around_expr ( around_expr )* [ "AND" around_expr ]*
around_expr      → unary_expr [ "AROUND" NUMBER? unary_expr ]
unary_expr       → "-" primary | "+" primary | primary
primary          → "(" expression ")" 
                 | "{" or_list "}"
                 | operator ":" value
                 | quoted_string
                 | word
```

### Key Features

- **Implicit AND**: Adjacent terms are combined with AND
- **Braces as OR**: `{a b c}` is equivalent to `a OR b OR c`
- **Negation**: `-term` creates a NOT node
- **Grouping**: Parentheses override precedence
- **Operator values**: Can be words, emails, numbers, dates, or even grouped expressions

## AST Structure

The AST is a minimal tree representation with the following node types:

### Node Types

#### `Operator`
Represents a search operator (from, to, subject, etc.)
```ruby
name: String        # "from", "to", "subject", etc.
value: String|Node  # Value or nested expression
```

#### `Text`
Plain text search term.
```ruby
value: String
```

#### `And`
Logical AND combination with 2 or more operands.
```ruby
operands: [Node]  # Array of 2+ nodes
```

#### `Or`
Logical OR combination with 2 or more operands.
```ruby
operands: [Node]  # Array of 2+ nodes
```

#### `Not`
Negation (exclusion).
```ruby
child: Node
```

#### `Group`
Parenthesized grouping.
```ruby
children: [Node]
```

#### `Around`
Proximity search.
```ruby
left: Node
distance: Integer  # Default: 5
right: Node
```

## Supported Operators

Based on Gmail's official documentation:

### Email Routing
- `from:`, `to:`, `cc:`, `bcc:`, `deliveredto:`

### Metadata
- `subject:`, `label:`, `category:`, `list:`

### Dates & Times
- `after:`, `before:`, `older:`, `newer:`, `older_than:`, `newer_than:`

### Attachments
- `has:`, `filename:`

### Status & Location
- `is:`, `in:`

### Size
- `size:`, `larger:`, `smaller:`

### Advanced
- `rfc822msgid:`

## Examples

### Simple Query
```ruby
Input: "from:amy@example.com"
AST:   Operator("from", "amy@example.com")
```

### Logical OR
```ruby
Input: "from:amy OR from:bob"
AST:   Or([
         Operator("from", "amy"),
         Operator("from", "bob")
       ])
```

### Multiple OR
```ruby
Input: "{from:a from:b from:c}"
AST:   Or([
         Operator("from", "a"),
         Operator("from", "b"),
         Operator("from", "c")
       ])
```

### Implicit AND
```ruby
Input: "subject:meeting has:attachment"
AST:   And([
         Operator("subject", "meeting"),
         Operator("has", "attachment")
       ])
```

### Multiple AND
```ruby
Input: "from:boss subject:urgent has:attachment"
AST:   And([
         Operator("from", "boss"),
         Operator("subject", "urgent"),
         Operator("has", "attachment")
       ])
```

### Negation
```ruby
Input: "dinner -movie"
AST:   And([
         Text("dinner"),
         Not(Text("movie"))
       ])
```

### Proximity Search
```ruby
Input: "holiday AROUND 10 vacation"
AST:   Around(
         Text("holiday"),
         10,
         Text("vacation")
       )
```

### Complex Query
```ruby
Input: "(from:boss OR from:manager) subject:urgent -label:spam"
AST:   And([
         Or([
           Operator("from", "boss"),
           Operator("from", "manager")
         ]),
         Operator("subject", "urgent"),
         Not(Operator("label", "spam"))
       ])
```

### Grouped Operator Values
```ruby
Input: "subject:(dinner movie)"
AST:   Operator("subject",
         And([
           Text("dinner"),
           Text("movie")
         ])
       )
```

## Testing

The parser includes comprehensive test coverage:

- **70 tests** across two test suites
- **346 assertions** verifying behavior
- Tests for all operators from Gmail documentation
- Edge case handling (empty queries, nested groups, etc.)
- Separate tokenizer tests with strict order verification

Run tests:
```bash
bundle exec rake test
```

## Usage

```ruby
require 'gmail_search_syntax'

ast = GmailSearchSyntax.parse!("from:manager subject:meeting")
# => #<And #<Operator from: "manager"> AND #<Operator subject: "meeting">>

# Access AST nodes
ast.operands[0].name   # => "from"
ast.operands[0].value  # => "manager"
ast.operands[1].name   # => "subject"
ast.operands[1].value  # => "meeting"

# Empty queries raise an error
begin
  GmailSearchSyntax.parse!("")
rescue GmailSearchSyntax::EmptyQueryError => e
  puts e.message  # => "Query cannot be empty"
end
```

## Design Decisions

1. **Minimal AST**: No redundant nodes; single-child nodes are collapsed
2. **Multi-operand AND/OR**: Support 2+ operands instead of binary left/right structure
3. **Strict tokenization**: Emails, dates, and numbers are recognized at tokenization
4. **Operator precedence**: Matches Gmail's actual behavior
5. **Implicit AND**: Adjacent terms combine naturally
6. **Value flexibility**: Operator values can be expressions (for grouping)
7. **Fail-fast on empty**: `parse!` raises `EmptyQueryError` for empty/whitespace-only input

## Extensions

The parser is designed to be extended:

1. Add semantic validation (valid operator names, date formats)
2. Convert AST to other query formats (SQL, Elasticsearch)
3. Add query optimization (flatten nested ANDs/ORs)
4. Pretty-print queries
5. Query builder API

