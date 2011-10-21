require "lattescript/version"
require "lattescript/grammar.kpeg"
require "lattescript/stringifier"
require "lattescript/ast"

module LatteScript
  def self.parse(string)
    parser = LatteScript::Parser.new(string)
    parser.parse
    parser.result
  end
  # Your code goes here...
end
