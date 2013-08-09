RAILS_ENV = "test" unless defined? RAILS_ENV

require "spec_helper"
Dir[File.dirname(__FILE__) + '/support/*.rb'].each {|file| require file }
