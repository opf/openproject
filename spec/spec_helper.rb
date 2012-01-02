RAILS_ENV = "test" unless defined? RAILS_ENV

# prevent case where we are using rubygems and test-unit 2.x is installed
begin
  require 'rubygems'
  gem "test-unit", "~> 1.2.3"
rescue LoadError
end

require './spec/spec_helper'

require 'redmine_factory_girl'

require 'prawn'
require 'pdf/inspector'
