# Implementation Notes: StringToken vs Substring Nodes

## Overview

This implementation distinguishes between **word boundary matching** (unquoted text) and **substring matching** (quoted text) in the Gmail search syntax parser.

## Changes Made

### 1. Renamed and New AST Nodes

- **Renamed** `Text` to `StringToken` for clarity - represents unquoted text tokens
- **Added** `Substring` node to the AST (`lib/gmail_search_syntax/ast.rb`) that represents quoted strings.

```ruby
class Substring < Node
  attr_reader :value
  
  def initialize(value)
    @value = value
  end
  
  def inspect
    "#<Substring #{@value.inspect}>"
  end
end
```

### 2. Parser Updates

Modified the parser (`lib/gmail_search_syntax/parser.rb`) to create:
- `StringToken` nodes for unquoted text
- `Substring` nodes for quoted strings (`:quoted_string` tokens)

### 3. SQL Visitor Updates

Updated the SQL visitor (`lib/gmail_search_syntax/sql_visitor.rb`) with two different behaviors:

#### StringToken Node (Word Boundary Matching)
```ruby
def visit_string_token(node)
  # Matches complete words only
  # Uses: = exact, LIKE "value %", LIKE "% value", LIKE "% value %"
end
```

SQL Pattern:
```sql
(m0.subject = ? OR m0.subject LIKE ? OR m0.subject LIKE ? OR m0.subject LIKE ?)
OR
(m0.body = ? OR m0.body LIKE ? OR m0.body LIKE ? OR m0.body LIKE ?)
```

Parameters: `["meeting", "meeting %", "% meeting", "% meeting %", ...]`

**Matches:** "meeting tomorrow", "the meeting", "just meeting"  
**Does NOT match:** "meetings", "premeeting", "meetingroom"

#### Substring Node (Partial Matching)
```ruby
def visit_substring(node)
  # Matches anywhere in the text
  # Uses: LIKE "%value%"
end
```

SQL Pattern:
```sql
(m0.subject LIKE ? OR m0.body LIKE ?)
```

Parameters: `["%meeting%", "%meeting%"]`

**Matches:** "meeting", "meetings", "premeeting", "meetingroom"

## Examples

### Unquoted (Word Boundary)
```ruby
GmailSearchSyntax.parse!("meeting")
# => #<StringToken "meeting">
# SQL: ... WHERE m0.subject = ? OR m0.subject LIKE ? OR ...
```

### Quoted (Substring)
```ruby
GmailSearchSyntax.parse!('"meeting"')
# => #<Substring "meeting">
# SQL: ... WHERE m0.subject LIKE ? OR m0.body LIKE ?
```

### Combined
```ruby
GmailSearchSyntax.parse!('urgent "q1 report"')
# => #<And #<StringToken "urgent"> AND #<Substring "q1 report">>
```

## Rationale

This implementation provides:

1. **More precise searching** - Unquoted text matches complete words/tokens, avoiding false positives from partial matches
2. **Flexible substring search** - Quoted text still allows finding substrings when needed
3. **Gmail-like behavior** - Aligns with user expectations from Gmail's search syntax
4. **SQL efficiency** - Word boundary matching is more specific than substring matching

## Escape Sequences

Both `StringToken` and `Substring` nodes support escape sequences in **both quoted and unquoted tokens**:

### Supported Escapes

- `\"` - Literal double quote
- `\\` - Literal backslash
- Other escape sequences (e.g., `\n`, `\t`) are preserved as-is (backslash + character)

### Examples

**Quoted Strings (Substring nodes):**
```ruby
# Escaped quotes in quoted string
'"She said \\"hello\\" to me"'
# => #<Substring 'She said "hello" to me'>

# Escaped backslashes in quoted string
'"path\\\\to\\\\file"'
# => #<Substring 'path\\to\\file'>

# In operator values with quoted strings
'subject:"Meeting: \\"Q1 Review\\""'
# => #<Operator subject: 'Meeting: "Q1 Review"'>
```

**Unquoted Tokens (StringToken nodes):**
```ruby
# Escaped quotes in unquoted token
'meeting\\"room'
# => #<StringToken 'meeting"room'>

# Escaped backslashes in unquoted token
'path\\\\to\\\\file'
# => #<StringToken 'path\\to\\file'>

# In operator values with unquoted tokens
'subject:test\\"value'
# => #<Operator subject: 'test"value'>
```

This allows you to include literal quotes and backslashes in any token, whether quoted or unquoted.

## Testing

All tests pass with comprehensive coverage:
- Basic functionality tests
- Escape sequence tests in tokenizer
- Integration tests for parsing with escaped quotes
- SQL generation tests with escaped quotes

New tests added:
- `test_quoted_text_search_uses_substring` in `test/sql_visitor_test.rb`
- `test_tokenize_quoted_string_with_escaped_quote` in `test/tokenizer_test.rb`
- `test_tokenize_quoted_string_with_escaped_backslash` in `test/tokenizer_test.rb`
- `test_tokenize_word_with_escaped_quote` in `test/tokenizer_test.rb`
- `test_tokenize_word_with_escaped_backslash` in `test/tokenizer_test.rb`
- `test_quoted_string_with_escaped_quotes` in `test/gmail_search_syntax_test.rb`
- `test_unquoted_text_with_escaped_quote` in `test/gmail_search_syntax_test.rb`
- `test_unquoted_text_with_escaped_backslash` in `test/gmail_search_syntax_test.rb`
- `test_subject_with_escaped_quotes` in `test/sql_visitor_test.rb`
- `test_unquoted_token_with_escaped_quote` in `test/sql_visitor_test.rb`
- `test_operator_with_unquoted_escaped_quote` in `test/sql_visitor_test.rb`

Run demos:
- `bundle exec ruby examples/text_vs_substring_demo.rb`
- `bundle exec ruby examples/escaped_quotes_demo.rb`

