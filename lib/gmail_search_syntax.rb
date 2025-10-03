# Gmail Search Syntax Parser
#
# Parses Gmail search queries into an Abstract Syntax Tree (AST).
# Based on the official Gmail search operators documentation:
# https://support.google.com/mail/answer/7190
#
# Example:
#   ast = GmailSearchSyntax.parse!("from:boss subject:meeting")
#   # => #<And #<Operator from: "boss"> AND #<Operator subject: "meeting">>

require_relative "gmail_search_syntax/version"
require_relative "gmail_search_syntax/tokenizer"
require_relative "gmail_search_syntax/parser"
require_relative "gmail_search_syntax/ast"
require_relative "gmail_search_syntax/sql_visitor"

module GmailSearchSyntax
  class EmptyQueryError < StandardError; end

  def self.parse!(query)
    tokens = Tokenizer.new(query).tokenize
    Parser.new(tokens).parse!
  end
end
