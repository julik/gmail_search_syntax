# Gmail Search Syntax Parser
#
# Parses Gmail search queries into an Abstract Syntax Tree (AST).
# Based on the official Gmail search operators documentation:
# https://support.google.com/mail/answer/7190
#
# Example:
#   ast = GmailSearchSyntax.parse!("from:boss subject:meeting")
#   # => #<And #<Operator from: "boss"> AND #<Operator subject: "meeting">>

module GmailSearchSyntax
  require_relative "gmail_search_syntax/version"
  autoload :Tokenizer, "gmail_search_syntax/tokenizer"
  autoload :Parser, "gmail_search_syntax/parser"
  autoload :AST, "gmail_search_syntax/ast"
  autoload :SQLiteVisitor, "gmail_search_syntax/sql_visitor"
  autoload :PostgresVisitor, "gmail_search_syntax/sql_visitor"

  # Backward compatibility alias (defined lazily)
  def self.const_missing(name)
    if name == :SqlVisitor
      const_set(:SqlVisitor, SQLiteVisitor)
    else
      super
    end
  end

  class EmptyQueryError < StandardError; end

  def self.parse!(query)
    tokens = Tokenizer.new(query).tokenize
    Parser.new(tokens).parse!
  end
end
