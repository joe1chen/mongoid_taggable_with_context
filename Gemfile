source 'https://rubygems.org'

gemspec

# CI matrix (see .github/workflows/test.yml): MONGOID_VERSION / RAILS_VERSION select versions.
# Defaults match what dogo-web runs today (Rails 6.1 / Mongoid 7.5).
rails_version = ENV['RAILS_VERSION'] || "6.1"
gem "rails", "~> #{rails_version}.0"

mongoid_version = ENV['MONGOID_VERSION'] || "7.5"
gem "mongoid", "~> #{mongoid_version}.0"
gem "mongo", "~> #{ENV['MONGO_DRIVER_VERSION']}.0" unless ENV['MONGO_DRIVER_VERSION'].to_s.empty?

# ActiveSupport < 7.1 breaks with concurrent-ruby >= 1.3.5 (Logger no longer preloaded).
gem "concurrent-ruby", "< 1.3.5" if Gem::Version.new(rails_version) < Gem::Version.new("7.1")
