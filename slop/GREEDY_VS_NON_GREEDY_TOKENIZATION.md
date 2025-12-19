# Greedy vs Non-Greedy Operator Value Tokenization

## Summary

This document explains the fix in `bugfix-tokens` that changes how operator values are parsed from **greedy** (consuming multiple barewords) to **non-greedy** (single token only), matching Gmail's actual search behavior.

## The Problem

The previous implementation used greedy tokenization for operator values. When parsing `label:Cora/Google Drive`, the parser would consume all subsequent barewords (`Cora/Google`, `Drive`) into the operator's value until hitting another operator or special token.

**Previous behavior:**
```
label:Cora/Google Drive label:Notes
→ Operator(label, "Cora/Google Drive"), Operator(label, "Notes")
```

**Gmail's actual behavior:**
```
label:Cora/Google Drive label:Notes
→ Operator(label, "Cora/Google"), StringToken("Drive"), Operator(label, "Notes")
```

## Gmail's Actual Behavior

In Gmail search, barewords after an operator are treated as **separate search terms**, not as part of the operator's value. To include multiple words in an operator value, you must explicitly quote them:

| Input | Gmail Interpretation |
|-------|---------------------|
| `subject:urgent meeting` | Subject contains "urgent" AND body contains "meeting" |
| `subject:"urgent meeting"` | Subject contains "urgent meeting" |
| `in:anywhere movie` | Search "movie" in all mail locations |
| `label:test one two` | Label is "test" AND body contains "one" AND "two" |

## The Fix

Changed `parse_operator_value` in `lib/gmail_search_syntax/parser.rb` to only consume a single token for bareword values (`:word`, `:email`, `:number`, `:date`, `:relative_time`).

### Before (greedy)

```ruby
when :word, :email, :number, :date, :relative_time
  values = []
  types = []

  # Collect barewords until operator or special token
  while !eof? && is_bareword_token?
    if current_token.type == :word && peek_token&.type == :colon
      break
    end
    values << current_token.value
    types << current_token.type
    advance
  end

  # Join multiple values as string
  values.map(&:to_s).join(" ")
```

### After (non-greedy)

```ruby
when :word, :email, :number, :date, :relative_time
  # Take only a single token as the operator value.
  # Multi-word values must be explicitly quoted: from:"john smith"
  value = current_token.value
  advance
  value.is_a?(Integer) ? value : value.to_s
```

## Test Changes

Updated tests to reflect the corrected behavior:

| Test | Previous Expected | Now Expected |
|------|-------------------|--------------|
| `in:anywhere movie` | `Operator("in", "anywhere movie")` | `Operator("in", "anywhere")`, `StringToken("movie")` |
| `subject:urgent meeting important` | `Operator("subject", "urgent meeting important")` | `Operator("subject", "urgent")`, `StringToken("meeting")`, `StringToken("important")` |
| `label:test one two three label:another` | 2 operands | 5 operands |

## Implications

1. **Breaking change** for consumers relying on greedy behavior
2. Users must now quote multi-word operator values explicitly
3. More accurate translation to SQL/other query languages since the semantics now match Gmail
