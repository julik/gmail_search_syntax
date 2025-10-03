require_relative 'gmail_search_syntax/version'
require_relative 'gmail_search_syntax/tokenizer'
require_relative 'gmail_search_syntax/parser'
require_relative 'gmail_search_syntax/ast'

module GmailSearchSyntax
  class EmptyQueryError < StandardError; end

  def self.parse!(query)
    tokens = Tokenizer.new(query).tokenize
    Parser.new(tokens).parse!
  end
end
