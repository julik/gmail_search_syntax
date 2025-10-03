$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "gmail_search_syntax"

# This example demonstrates the difference between SQLite and PostgreSQL
# SQL generation, particularly for relative date operators

queries = [
  "older_than:7d",
  "newer_than:3m",
  "from:alice@example.com older_than:1y",
  "subject:meeting newer_than:2d"
]

queries.each do |query_string|
  puts "\n" + "=" * 80
  puts "Query: #{query_string}"
  puts "=" * 80

  ast = GmailSearchSyntax.parse!(query_string)

  # SQLite version
  puts "\n--- SQLite ---"
  sqlite_visitor = GmailSearchSyntax::SQLiteVisitor.new(current_user_email: "me@example.com")
  sqlite_visitor.visit(ast)
  sqlite_sql, sqlite_params = sqlite_visitor.to_query.to_sql

  puts "SQL:"
  puts sqlite_sql
  puts "\nParameters:"
  sqlite_params.each_with_index do |param, idx|
    puts "  #{idx + 1}. #{param.inspect}"
  end

  # PostgreSQL version
  puts "\n--- PostgreSQL ---"
  postgres_visitor = GmailSearchSyntax::PostgresVisitor.new(current_user_email: "me@example.com")
  postgres_visitor.visit(ast)
  postgres_sql, postgres_params = postgres_visitor.to_query.to_sql

  puts "SQL:"
  puts postgres_sql
  puts "\nParameters:"
  postgres_params.each_with_index do |param, idx|
    puts "  #{idx + 1}. #{param.inspect}"
  end
end

puts "\n" + "=" * 80
puts "Key Differences:"
puts "=" * 80
puts "- SQLite uses: datetime('now', '-7 days')"
puts "- PostgreSQL uses: NOW() - '7 days'::interval"
puts "- The relative time parameter format differs:"
puts "  * SQLite: '-7 days' (negative number)"
puts "  * PostgreSQL: '7 days' (positive number with cast)"
