# Embedded Hyphens in Gmail Search

## Gmail's Actual Behavior

Gmail treats hyphens differently depending on whether they are preceded by whitespace:

### Embedded Hyphen (No Preceding Whitespace)

When a hyphen appears immediately after a word character (no space before it), Gmail treats it as a **word separator**, not a negation operator. Both parts become separate search tokens that are implicitly ANDed together.

```
Coxlee-Gammage
```

Gmail behavior: Search for messages containing both "Coxlee" AND "Gammage". Both tokens get highlighted in search results.

Parsed as:
```ruby
GmailSearchSyntax.parse!("Coxlee-Gammage")
# => #<And [#<StringToken "Coxlee">, #<StringToken "Gammage">]>
```

### Space + Hyphen (Negation)

When a hyphen is preceded by whitespace (or at the start of input), it functions as the **negation operator**.

```
Coxlee -Gammage
```

Gmail behavior: Search for messages containing "Coxlee" but NOT "Gammage".

Parsed as:
```ruby
GmailSearchSyntax.parse!("Coxlee -Gammage")
# => #<And [#<StringToken "Coxlee">, #<Not #<StringToken "Gammage">>]>
```

## Examples

| Query | Parsed As | Meaning |
|-------|-----------|---------|
| `some-outfit` | `some AND outfit` | Contains both "some" and "outfit" |
| `some -outfit` | `some AND NOT outfit` | Contains "some" but not "outfit" |
| `a-b-c` | `a AND b AND c` | Contains all three tokens |
| `-spam` | `NOT spam` | Does not contain "spam" |
| `cats-dogs -birds` | `cats AND dogs AND NOT birds` | Contains "cats" and "dogs", not "birds" |

## Real-World Use Cases

### Hyphenated Names
```
from:Mary-Jane
```
Searches for emails where "from" contains "Mary" AND message contains "Jane".

### Hyphenated Terms
```
self-service
```
Finds messages containing both "self" and "service".

### Compound Words
```
e-commerce
```
Finds messages containing both "e" and "commerce".

## Implementation Details

The fix is in the tokenizer (`lib/gmail_search_syntax/tokenizer.rb`). When encountering a `-` character:

1. Check if there's a non-whitespace character following (potential negation or word separator)
2. Check if there's whitespace (or nothing) preceding the hyphen
3. If preceded by whitespace or at start of input: treat as negation operator (`:minus` token)
4. If preceded by non-whitespace: skip the hyphen (acts as word separator, no token emitted)

```ruby
when "-"
  next_char = peek_char
  prev_char = @position > 0 ? @input[@position - 1] : nil

  if next_char && next_char !~ /\s/ && (prev_char.nil? || prev_char =~ /\s/)
    # Negation: preceded by whitespace or at start, followed by non-whitespace
    add_token(:minus, char)
    advance
  elsif prev_char && prev_char !~ /\s/
    # Embedded hyphen: preceded by non-whitespace - skip as word separator
    advance
  else
    read_word
  end
```

## Bug That Was Fixed

Previously, the gem incorrectly treated all hyphens followed by non-whitespace as negation:

- **Old (incorrect):** `some-outfit` was parsed as `some AND NOT outfit`
- **New (correct):** `some-outfit` is parsed as `some AND outfit`

This matches Gmail's actual search behavior where hyphenated terms find messages containing both parts of the hyphenated word.
