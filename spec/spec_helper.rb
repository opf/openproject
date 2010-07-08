ENV["RAILS_ENV"] ||= "test"

# prevent case where we are using rubygems and test-unit 2.x is installed
begin
  require 'rubygems'
  gem "test-unit", "~> 1.2.3"
rescue LoadError
end

begin
  require 'ci/reporter/rake/rspec'     # use this if you're using RSpec
  require 'ci/reporter/rake/test_unit' # use this if you're using Test::Unit
rescue LoadError
  puts <<-EOS
    Missing the CI Reporter gem. This is not fatal.
    If you want XML output for the CI, execute

        gem install ci_reporter

  EOS
end

begin
  #require "config/environment" unless defined? RAILS_ROOT
  require 'spec/spec_helper'
rescue LoadError => error
  puts <<-EOS

    You need to install rspec in your Redmine project.
    Please execute the following code:
    
      gem install rspec-rails
      script/generate rspec

  EOS
  raise error
end

Fixtures.create_fixtures File.join(File.dirname(__FILE__), "fixtures"), ActiveRecord::Base.connection.tables
