require "lattescript"
require "digest"

describe "stringifying" do
  def should_equal_itself(string)
    string = "#{string}\n"

    ast = LatteScript.parse(string)
    new_string = LatteScript::Stringifier.to_string(ast)

    new_string.should == string
  end

  def self.strip(string)
    string.gsub(/^ {6}/, '').strip
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
    ("x + y - " * 100) + "z;",
    "x.y = z;",
    "get(id).text = f();",
    "[,] = x;",
    "x = 1e999 + y;",
    "x = y / -1e999;",
    "x = 0 / 0;",
    "x = (-1e999).toString();",

    # statements
    strip(<<-IF),
      if (a == b)
        x();
      else
        y();
    IF

    strip(<<-IF),
      if (a == b) {
        x();
      } else {
        y();
      }
    IF

    strip(<<-IF),
      if (a == b)
        if (b == c)
          x();
        else
          y();
    IF
  ].each do |string|

    it "correctly parses and stringifies '#{string.inspect}' - #{Digest::MD5.hexdigest(string)}" do
      should_equal_itself string
    end

  end
end
