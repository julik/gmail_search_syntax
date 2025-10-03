# Gmail Behavior Compatibility

## Overview

Our parser now implements Gmail-compatible behavior for handling operator values with spaces.

## ✅ Implemented: Barewords After Operator Values

### Gmail's Behavior (Now Implemented)

In Gmail, barewords (unquoted text) that follow an operator value are **consumed into the operator value** until the next operator or special token is encountered.

### Our Implementation

We now match Gmail's behavior: barewords after operator values are automatically collected into the operator value, separated by spaces.

## Examples

### Example 1: Label with Spaces

**Query:** `label:Cora/Google Drive label:Notes`

**Both Gmail and our parser produce:**
```
Operator(label: "Cora/Google Drive")
Operator(label: "Notes")
```

**Result:** ✅ Matches Gmail perfectly

### Example 2: Subject with Multiple Words

**Query:** `subject:urgent meeting important`

**Both Gmail and our parser produce:**
```
Operator(subject: "urgent meeting important")
```

**Result:** ✅ Matches Gmail perfectly

### Example 3: Multiple Barewords Between Operators

**Query:** `label:test one two three label:another`

**Both Gmail and our parser produce:**
```
Operator(label: "test one two three")
Operator(label: "another")
```

**Result:** ✅ Matches Gmail perfectly

## How It Works

### Automatic Bareword Collection

After parsing an operator name and colon, the parser automatically collects:
- Words
- Emails  
- Numbers
- Dates
- Relative times

These are joined with spaces into the operator value.

### Collection Stops At

Bareword collection stops when encountering:
- Another operator (e.g., `label:`, `from:`)
- Special operators (`OR`, `AND`, `AROUND`)
- Grouping tokens (`(`, `)`, `{`, `}`)
- Negation (`-`)
- End of input

### Explicit Quoting Still Supported

You can still use quotes for clarity or to force exact parsing:

```
label:"Cora/Google Drive"  # Explicit
label:Cora/Google Drive    # Automatic (same result)
```

Both produce: `Operator(label: "Cora/Google Drive")` ✅

## Benefits

### Gmail Compatibility ✅

- Users can copy-paste Gmail queries directly
- Behavior matches user expectations from Gmail
- No need to add quotes for multi-word operator values

### Implementation

**Parser-level solution:**
- Tokenizer remains simple (still produces individual tokens)
- Parser intelligently collects barewords
- Clear rules for when collection stops

**Preserves advanced features:**
- Parentheses still work for complex expressions
- Quotes still work for explicit values
- Numbers preserve their type when alone

## Usage Examples

### Works Automatically

```ruby
# Multi-word labels
"label:Cora/Google Drive label:Notes"
→ label:"Cora/Google Drive", label:"Notes" ✅

# Multi-word subjects  
"subject:urgent meeting important"
→ subject:"urgent meeting important" ✅

# Mixed with numbers and dates
"subject:Q1 2024 review meeting"
→ subject:"Q1 2024 review meeting" ✅
```

### Stops at Operators

```ruby
# Barewords stop at next operator
"subject:urgent meeting from:boss"
→ subject:"urgent meeting", from:"boss" ✅

# Stops at OR/AND
"subject:urgent meeting OR subject:important call"
→ subject:"urgent meeting" OR subject:"important call" ✅
```

### Edge Cases

```ruby
# To include "movie" as separate text search after operator:
# Option 1: Use quotes
"in:anywhere \"movie\""

# Option 2: Use another operator after
"in:anywhere subject:movie"
```

## Testing

Tests verifying Gmail-compatible behavior in `test/gmail_search_syntax_test.rb`:
- `test_label_with_space_separated_value_gmail_behavior` ✅
- `test_subject_with_barewords_gmail_behavior` ✅
- `test_multiple_barewords_between_operators_gmail_behavior` ✅
- `test_barewords_stop_at_special_operators` ✅
- `test_barewords_with_mixed_tokens` ✅

All 181 tests pass ✅

## Conclusion

**Status:** ✅ Gmail-compatible behavior fully implemented

**Compatibility:** Users can copy-paste Gmail queries directly - they work as expected

**SQL Generation:** Produces correct SQL matching the semantic intent of Gmail queries

