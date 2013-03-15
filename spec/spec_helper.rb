RAILS_ENV = "test" unless defined? RAILS_ENV

require 'spec/spec_helper'
require 'redmine_factory_girl'
require 'identical_ext'
require File.join(File.dirname(__FILE__), "plugin_spec_helper")

Fixtures.create_fixtures File.join(File.dirname(__FILE__), "fixtures"), ActiveRecord::Base.connection.tables
