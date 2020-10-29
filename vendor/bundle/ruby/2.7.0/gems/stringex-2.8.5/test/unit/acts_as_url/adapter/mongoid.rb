gem 'mongoid'
require 'mongoid'
require 'stringex'
# Reload adapters to make sure ActsAsUrl sees the ORM
Stringex::ActsAsUrl::Adapter.load_available

puts "-------------------------------------------------"
puts "Running ActsAsUrl tests with Mongoid adapter"
puts "-------------------------------------------------"

Mongoid.configure do |config|
  config.connect_to('acts_as_url')
end

class Document
  include Mongoid::Document
  field :title,   type: String
  field :other,   type: String
  field :another, type: String
  field :url,     type: String

  acts_as_url :title
end

begin
  # Let's make sure we can connect to mongodb before we run our tests!
  Mongoid::Sessions.default.databases
rescue Moped::Errors::ConnectionFailure => err
  puts 'Cannot connect to mongodb. Aborting.'
  exit
end

class STIBaseDocument
  include Mongoid::Document
  field :title,   type: String
  field :other,   type: String
  field :another, type: String
  field :url,     type: String
  field :type,    type: String

  # This gets redefined in the only test that uses it but I want to be uniform
  # in setting configuration details in the tests themselves
  acts_as_url :title
end

class STIChildDocument < STIBaseDocument
end

class AnotherSTIChildDocument < STIBaseDocument
end

module AdapterSpecificTestBehaviors
  def setup
    # No setup tasks at present
  end

  def teardown
    [Document, STIBaseDocument].each do |klass|
      klass.delete_all
      # Reset behavior to default
      klass.class_eval do
        acts_as_url :title
      end
    end
  end

  def add_validation_on_document_title
    Document.class_eval do
      validates_presence_of :title
    end
  end

  def remove_validation_on_document_title
    Document.class_eval do
      _validators.delete :title
    end
  end

  def adapter_specific_update(instance, hash)
    instance.send :update_attributes!, hash
  end
end
