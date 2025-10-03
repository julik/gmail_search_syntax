require_relative '../lib/gmail_search_syntax'

puts "Gmail Search Syntax Parser - Demo"
puts "=" * 50
puts

queries = [
  "from:amy@example.com",
  "subject:meeting has:attachment",
  "from:boss OR from:manager",
  "{from:amy from:bob from:charlie}",
  "dinner -movie",
  "holiday AROUND 10 vacation",
  'from:manager subject:"quarterly review" after:2024/01/01',
  "is:unread label:important -label:spam",
  "(from:team OR from:boss) subject:urgent",
  "from:(mischa@ OR julik@) subject:meeting",
  "to:(alice@ OR bob@ OR charlie@)",
  "from:{mischa@ marc@}",
  "from:{alice@ bob@} to:{charlie@ david@}"
]

queries.each do |query|
  puts "Query: #{query}"
  ast = GmailSearchSyntax.parse!(query)
  puts "AST:   #{ast.inspect}"
  puts
end

