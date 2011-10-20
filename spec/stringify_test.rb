require "lattescript"

describe "stringifying" do
  def should_equal_itself(string)
    ast = LatteScript.parse(string)
    new_string = LatteScript::Stringifier.to_string(ast)

    string.should == new_string
  end

  [
    "x;",
    "null;",
    "true;",
    "false;",
    "-0;",
    "x = y;",
    "void 0;",
    "void y;",
    "void f();",
    "[];",
    "({});",
    "({1e999: 0});",
    "[, , 2];",
    "[, 1, ,];",
    "[1, , , 2, , ,];",
    "[, , ,];",
    "[0, 1, 2, \"x\"];"
  ].each do |string|

    it "correctly parses and stringifies #{string.inspect}" do
      should_equal_itself string
    end

  end
end
