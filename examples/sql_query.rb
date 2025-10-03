require_relative "../lib/gmail_search_syntax"

queries = [
  "from:amy@example.com",
  "from:@example.com",
  "from:amy AND to:bob",
  "subject:meeting has:attachment",
  "label:important is:unread",
  "after:2024/01/01 -from:spam@example.com",
  'from:(amy@example.com OR bob@example.com) subject:"urgent meeting"',
  "larger:10M filename:pdf",
  "category:primary is:starred"
]

queries.each do |query_string|
  puts "\n" + "=" * 80
  puts "Query: #{query_string}"
  puts "=" * 80

  ast = GmailSearchSyntax.parse!(query_string)
  visitor = GmailSearchSyntax::SqlVisitor.new(current_user_email: "me@example.com")
  visitor.visit(ast)

  sql, params = visitor.to_query.to_sql

  puts "\nSQL:"
  puts sql

  puts "\nParameters:"
  params.each_with_index do |param, idx|
    puts "  #{idx + 1}. #{param.inspect}"
  end
end

puts "\n" + "=" * 80
puts "AROUND operator (generates no-op condition):"
puts "=" * 80

ast = GmailSearchSyntax.parse!("holiday AROUND 10 vacation")
visitor = GmailSearchSyntax::SqlVisitor.new
visitor.visit(ast)
sql, _ = visitor.to_query.to_sql

puts "\nSQL:"
puts sql
puts "\nParameters:"
puts "  (none)"
