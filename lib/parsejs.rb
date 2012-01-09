require "parsejs/version"
require "parsejs/grammar.kpeg"
require "parsejs/stringifier"
require "parsejs/ast"

module ParseJS
  def self.parse(string)
    parser = ParseJS::Parser.new(string)
    parser.parse
    parser.result
  end
  # Your code goes here...
end
