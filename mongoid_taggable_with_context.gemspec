# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mongoid/taggable_with_context/version"

Gem::Specification.new do |s|
  s.name = "mongoid_taggable_with_context"
  s.version = Mongoid::TaggableWithContext::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors = ["Aaron Qian", "Luca G. Soave", "John Shields", "Wilker Lucio", "Ches Martin"]
  s.date = "2013-10-14"
  s.description = "Add multiple tag fields on Mongoid documents with aggregation capability."
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")

  s.homepage = "http://github.com/lgs/mongoid_taggable_with_context"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.summary = "Mongoid taggable behaviour"

  s.add_development_dependency "bundler"
  s.add_development_dependency "database_cleaner"
  s.add_development_dependency "jeweler"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "yard"
  s.add_runtime_dependency "mongoid"
  s.add_runtime_dependency "mongoid-compatibility"
end

