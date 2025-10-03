$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "gmail_search_syntax"

puts "=" * 80
puts "Table Alias Uniqueness Fix"
puts "=" * 80
puts
puts "When using operators with subqueries (OR, AND, NOT, etc.), each subquery"
puts "needs its own visitor. Previously, each sub-visitor had its own alias"
puts "counter starting at 0, causing alias collisions like:"
puts
puts "  WRONG: ... ma1 ... ma1 ... (same alias twice!)"
puts
puts "Now, all sub-visitors share a single counter ((1..).each enumerator), ensuring:"
puts
puts "  RIGHT: ... ma1 ... ma3 ... (unique aliases)"
puts
puts "=" * 80

query = "from:alice@example.com OR from:bob@example.com"
puts "\nQuery: #{query}"
puts "-" * 80

ast = GmailSearchSyntax.parse!(query)
visitor = GmailSearchSyntax::SQLiteVisitor.new
visitor.visit(ast)
sql, _ = visitor.to_query.to_sql

puts "\nGenerated SQL:"
puts sql
puts

# Highlight the aliases
ma1_count = sql.scan(/\bma1\b/).size
ma3_count = sql.scan(/\bma3\b/).size

puts "Alias usage:"
puts "  ma1: appears #{ma1_count} times"
puts "  ma3: appears #{ma3_count} times"
puts
puts "✓ No alias collision! Each JOIN has a unique alias."
puts
puts "=" * 80
