RAILS_ENV ||= "test"

# prevent case where we are using rubygems and test-unit 2.x is installed
begin
  require 'rubygems'
  gem "test-unit", "~> 1.2.3"
rescue LoadError
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
require File.expand_path(File.dirname(__FILE__) + '/helpers/plugin_spec_helper')