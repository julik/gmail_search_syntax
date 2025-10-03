#!/usr/bin/env ruby

require_relative "../lib/gmail_search_syntax"

puts "=" * 80
puts "Escaped Quotes Demo"
puts "=" * 80
puts

# Example 1: Escaped quotes in a substring search
puts "1. Substring with escaped quotes"
puts "-" * 40
query1 = '"She said \\"hello\\" to me"'
puts "Input: #{query1}"
ast1 = GmailSearchSyntax.parse!(query1)
puts "AST: #{ast1.inspect}"
puts "Value: #{ast1.value.inspect}"

visitor1 = GmailSearchSyntax::SQLiteVisitor.new
visitor1.visit(ast1)
sql1, params1 = visitor1.to_query.to_sql

puts "\nSQL:\n#{sql1}"
puts "\nParams: #{params1.inspect}"
puts

# Example 2: Escaped quotes in subject operator
puts "2. Subject with escaped quotes"
puts "-" * 40
query2 = 'subject:"Meeting: \\"Q1 Review\\""'
puts "Input: #{query2}"
ast2 = GmailSearchSyntax.parse!(query2)
puts "AST: #{ast2.inspect}"
puts "Operator: #{ast2.name}"
puts "Value: #{ast2.value.inspect}"

visitor2 = GmailSearchSyntax::SQLiteVisitor.new
visitor2.visit(ast2)
sql2, params2 = visitor2.to_query.to_sql

puts "\nSQL:\n#{sql2}"
puts "\nParams: #{params2.inspect}"
puts

# Example 3: Escaped backslashes
puts "3. Escaped backslashes"
puts "-" * 40
query3 = '"path\\\\to\\\\file"'
puts "Input: #{query3}"
ast3 = GmailSearchSyntax.parse!(query3)
puts "AST: #{ast3.inspect}"
puts "Value: #{ast3.value.inspect}"
puts

# Example 4: Mixed escapes
puts "4. Mixed escapes (quotes and backslashes)"
puts "-" * 40
query4 = '"He said: \\"C:\\\\Users\\\\file.txt\\""'
puts "Input: #{query4}"
ast4 = GmailSearchSyntax.parse!(query4)
puts "AST: #{ast4.inspect}"
puts "Value: #{ast4.value.inspect}"

visitor4 = GmailSearchSyntax::SQLiteVisitor.new
visitor4.visit(ast4)
sql4, params4 = visitor4.to_query.to_sql

puts "\nSQL:\n#{sql4}"
puts "\nParams: #{params4.inspect}"
puts

# Example 5: Complex query with escaped quotes
puts "5. Complex query with escaped quotes"
puts "-" * 40
query5 = 'from:boss subject:"\\"Important\\" Meeting" has:attachment'
puts "Input: #{query5}"
ast5 = GmailSearchSyntax.parse!(query5)
puts "AST: #{ast5.inspect}"

visitor5 = GmailSearchSyntax::SQLiteVisitor.new
visitor5.visit(ast5)
sql5, params5 = visitor5.to_query.to_sql

puts "\nSQL:\n#{sql5}"
puts "\nParams: #{params5.inspect}"
puts

# Example 6: Escaped quotes in unquoted tokens
puts "6. Unquoted token with escaped quote"
puts "-" * 40
query6 = 'meeting\\"room'
puts "Input: #{query6}"
ast6 = GmailSearchSyntax.parse!(query6)
puts "AST: #{ast6.inspect}"
puts "Value: #{ast6.value.inspect}"

visitor6 = GmailSearchSyntax::SQLiteVisitor.new
visitor6.visit(ast6)
sql6, params6 = visitor6.to_query.to_sql

puts "\nSQL:\n#{sql6}"
puts "\nParams: #{params6.inspect}"
puts "\nNote: Unquoted tokens use word boundary matching (not substring)"
puts

# Example 7: Escaped quotes in operator with unquoted value
puts "7. Operator with unquoted escaped quote"
puts "-" * 40
query7 = 'subject:test\\"value'
puts "Input: #{query7}"
ast7 = GmailSearchSyntax.parse!(query7)
puts "AST: #{ast7.inspect}"
puts "Operator: #{ast7.name}"
puts "Value: #{ast7.value.inspect}"

visitor7 = GmailSearchSyntax::SQLiteVisitor.new
visitor7.visit(ast7)
sql7, params7 = visitor7.to_query.to_sql

puts "\nSQL:\n#{sql7}"
puts "\nParams: #{params7.inspect}"
puts

# Example 8: Escaped backslash in unquoted token
puts "8. Unquoted token with escaped backslash"
puts "-" * 40
query8 = 'path\\\\to\\\\file'
puts "Input: #{query8}"
ast8 = GmailSearchSyntax.parse!(query8)
puts "AST: #{ast8.inspect}"
puts "Value: #{ast8.value.inspect}"
puts

puts "=" * 80
puts "Summary"
puts "=" * 80
puts "Escape sequences work in BOTH quoted and unquoted tokens:"
puts
puts "Quoted strings (Substring nodes):"
puts "  - Use substring matching (LIKE %value%)"
puts "  - \"She said \\\"hello\\\"\" → 'She said \"hello\"'"
puts
puts "Unquoted tokens (StringToken nodes):"
puts "  - Use word boundary matching (= or LIKE with boundaries)"
puts "  - meeting\\\"room → 'meeting\"room'"
puts "  - path\\\\to\\\\file → 'path\\to\\file'"
puts
puts "Supported escapes:"
puts "  \\\" → literal double quote"
puts "  \\\\ → literal backslash"
puts "  Other (\\n, \\t, etc.) → preserved as-is"
puts "=" * 80
