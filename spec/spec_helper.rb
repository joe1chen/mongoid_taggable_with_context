$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rspec'
require 'mongoid'
require 'mongoid_taggable_with_context.rb'

RSpec.configure do |config|
  # Clean up the database
  require "database_cleaner/mongoid"
  DatabaseCleaner[:mongoid].strategy = [:deletion]

  RSpec.configure do |c|
    c.before(:each) { DatabaseCleaner.clean }
  end
end

Mongoid.configure do |config|
  if Mongoid::Compatibility::Version.mongoid2?
    database = Mongo::Connection.new.db("mongoid_taggable_with_context_test")
    database.add_user("mongoid", "test")
    config.master = database
    config.logger = nil
  else
    name = "mongoid_taggable_with_context_test"
    config.respond_to?(:connect_to) ? config.connect_to(name) : config.master = Mongo::Connection.new.db(name)
  end
end