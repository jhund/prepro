# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "prepro/version"

Gem::Specification.new do |s|
  s.name        = 'prepro'
  s.version     = Prepro::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jo Hund"]
  s.email       = 'jhund@clearcove.ca'
  s.homepage    = 'http://rubygems.org/gems/prepro'
  s.summary     = "Presenters and Processors for clean Rails apps."
  s.description = "Presenters and Processors for clean Rails apps."

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
