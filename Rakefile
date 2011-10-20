#!/usr/bin/env rake
require "bundler/gem_tasks"
require "bundler/setup"

file "lib/lattescript/grammar.kpeg.rb" => "lib/lattescript/grammar.kpeg" do
  sh "kpeg -f lib/lattescript/grammar.kpeg --stand-alone --debug"
end

task :compile => "lib/lattescript/grammar.kpeg.rb"

task :default => :compile
