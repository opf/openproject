begin
  require 'simplecov'
  SimpleCov.start do
    add_group "Lib", 'lib'
  end
rescue LoadError
end

begin; require 'turn'; rescue LoadError; end

gem 'minitest'
require 'minitest/autorun'

require 'active_model'
require 'date_validator'

I18n.load_path += Dir[File.expand_path(File.join(File.dirname(__FILE__), '../config/locales', '*.yml')).to_s]

class TestRecord
  include ActiveModel::Validations
  attr_accessor :expiration_date

  def initialize(expiration_date)
    @expiration_date = expiration_date
  end
end
