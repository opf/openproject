RAILS_ENV = "test"

# prevent case where we are using rubygems and test-unit 2.x is installed
begin
  require 'rubygems'
  gem "test-unit", "~> 1.2.3"
rescue LoadError
end

begin
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

def l(*args)
  I18n.t(*args)
end

Fixtures.create_fixtures File.join(File.dirname(__FILE__), "fixtures"), ActiveRecord::Base.connection.tables
require File.join(RAILS_ROOT, "test", "object_daddy_helpers.rb")
Dir.glob(File.expand_path("#{__FILE__}/../../../redmine_costs/test/exemplars/*.rb")) { |e| require e }
Dir.glob(File.expand_path("#{__FILE__}/../models/helpers/*_helper.rb")) { |e| require e }
