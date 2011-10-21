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
    "[0, 1, 2, \"x\"];",
    "x.y.z;",
    "x[y[z]];",
    "x[\"y z\"];",
    "(0).toString();",
    "f()();",
    "f((x, y));",
    "f(x = 3);",
    "x.y();",
    "f(1, 2, 3, null, (g(), h));",
    "new (x.y);",
    "new (x());",
    "(new x).y;",
    "new (x().y);",
    "a * x + b * y;",
    "a * (x + b) * y;",
    "a + (b + c);",
    "a + b + c;",
  ].each do |string|

    it "correctly parses and stringifies '#{string}'" do
      should_equal_itself string
    end

  end
end
