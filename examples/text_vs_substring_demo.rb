#!/usr/bin/env ruby

require_relative "../lib/gmail_search_syntax"

puts "=" * 80
puts "LooseWord vs ExactWord Demo"
puts "=" * 80
puts

# Example 1: Unquoted text (LooseWord node) - word boundary matching
puts "1. Unquoted text: meeting"
puts "-" * 40
query1 = "meeting"
ast1 = GmailSearchSyntax.parse!(query1)
puts "AST: #{ast1.inspect}"
puts "Node type: #{ast1.class.name}"

visitor1 = GmailSearchSyntax::SQLiteVisitor.new
visitor1.visit(ast1)
sql1, params1 = visitor1.to_query.to_sql

puts "\nSQL:\n#{sql1}"
puts "\nParams: #{params1.inspect}"
puts "\nExplanation:"
puts "  - Matches 'meeting' as a complete word"
puts "  - Will match: 'meeting tomorrow', 'the meeting', 'just a meeting here'"
puts "  - Will NOT match: 'meetings', 'premeeting', 'meetingroom'"
puts

# Example 2: Quoted text (ExactWord node) - substring matching
puts "2. Quoted text: \"meeting\""
puts "-" * 40
query2 = '"meeting"'
ast2 = GmailSearchSyntax.parse!(query2)
puts "AST: #{ast2.inspect}"
puts "Node type: #{ast2.class.name}"

visitor2 = GmailSearchSyntax::SQLiteVisitor.new
visitor2.visit(ast2)
sql2, params2 = visitor2.to_query.to_sql

puts "\nSQL:\n#{sql2}"
puts "\nParams: #{params2.inspect}"
puts "\nExplanation:"
puts "  - Matches 'meeting' as a substring anywhere"
puts "  - Will match: 'meeting', 'meetings', 'premeeting', 'meetingroom'"
puts "  - This is useful for partial matching"
puts

# Example 3: Multi-word quoted phrase
puts "3. Quoted phrase: \"quarterly review\""
puts "-" * 40
query3 = '"quarterly review"'
ast3 = GmailSearchSyntax.parse!(query3)
puts "AST: #{ast3.inspect}"
puts "Node type: #{ast3.class.name}"

visitor3 = GmailSearchSyntax::SQLiteVisitor.new
visitor3.visit(ast3)
sql3, params3 = visitor3.to_query.to_sql

puts "\nSQL:\n#{sql3}"
puts "\nParams: #{params3.inspect}"
puts "\nExplanation:"
puts "  - Matches 'quarterly review' as a substring"
puts "  - Will match: 'quarterly review meeting', 'the quarterly review is done'"
puts

# Example 4: Combined usage
puts "4. Combined: urgent \"q1 report\""
puts "-" * 40
query4 = 'urgent "q1 report"'
ast4 = GmailSearchSyntax.parse!(query4)
puts "AST: #{ast4.inspect}"

visitor4 = GmailSearchSyntax::SQLiteVisitor.new
visitor4.visit(ast4)
sql4, params4 = visitor4.to_query.to_sql

puts "\nSQL:\n#{sql4}"
puts "\nParams: #{params4.inspect}"
puts "\nExplanation:"
puts "  - 'urgent' uses word boundary matching (complete word)"
puts "  - '\"q1 report\"' uses substring matching (partial match)"
puts "  - Both conditions must be satisfied (AND)"
puts

puts "=" * 80
puts "Summary"
puts "=" * 80
puts "LooseWord node (unquoted):  Word boundary matching - finds complete words"
puts "ExactWord node (quoted):      ExactWord matching - finds partial matches"
puts "=" * 80
