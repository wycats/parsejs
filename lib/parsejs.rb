require "parsejs/version"
require "parsejs/grammar.kpeg"
require "parsejs/stringifier"
require "parsejs/ast"
require "parsejs/scope"

module ParseJS
  def self.parse(string)
    parser = ParseJS::Parser.new(string)
    parser.parse
    parser.result
  end
end
