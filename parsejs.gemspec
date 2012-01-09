# -*- encoding: utf-8 -*-
$:.unshift File.expand_path("../lib", __FILE__)
require "parsejs/version"

Gem::Specification.new do |gem|
  gem.authors       = ["Yehuda Katz"]
  gem.email         = ["wycats@gmail.com"]
  gem.description   = %q{ParseJS is a JavaScript parser written using KPeg}
  gem.summary       = %q{ParseJS parses JavaScript into a Ruby AST, suitable for preprocessing and other purposes. It also has work-in-progress support for extracting documentation from JavaScript}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "parsejs"
  gem.require_paths = ["lib"]
  gem.version       = ParseJS::VERSION

  gem.add_dependency "kpeg"
  gem.add_dependency "yard"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "uglifier"
  gem.add_development_dependency "json"
end
