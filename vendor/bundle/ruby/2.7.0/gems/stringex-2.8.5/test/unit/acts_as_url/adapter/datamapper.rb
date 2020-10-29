gem 'dm-core'
gem 'dm-migrations'
gem 'dm-validations'
require 'dm-core'
require 'dm-migrations'
require 'dm-validations'
require 'stringex'
# Reload adapters to make sure ActsAsUrl sees the ORM
Stringex::ActsAsUrl::Adapter.load_available

puts "-------------------------------------------------"
puts "Running ActsAsUrl tests with DataMapper adapter"
puts "-------------------------------------------------"

DataMapper.setup :default, 'sqlite::memory:'

# What the tests do in constant redefining the same classes doesn't quite work with DataMapper.
# This proc allows us to reset the class definitions on each test. This might be more expensive
# but it definitely allows the class definitions to be correct. If someone more familiar with
# DataMapper than I am wants to refactor this, I'd be more than happy to take a look.
DefineTestClasses = proc do
  class Document
    include DataMapper::Resource
    property :id,      Serial
    property :title,   String
    property :other,   String
    property :another, String
    property :url,     String, lazy: false

    acts_as_url :title
  end

  class STIBaseDocument
    include DataMapper::Resource
    property :id,      Serial
    property :title,   String
    property :other,   String
    property :another, String
    property :url,     String, lazy: false
    property :type,    String

    # This gets redefined in the only test that uses it but I want to be uniform
    # in setting configuration details in the tests themselves
    acts_as_url :title
  end

  class STIChildDocument < STIBaseDocument
  end

  class AnotherSTIChildDocument < STIBaseDocument
  end

  DataMapper.finalize
  Document.auto_migrate!
  STIBaseDocument.auto_migrate!
end

module AdapterSpecificTestBehaviors
  def setup
    DefineTestClasses.call
  end

  def teardown
    [Document, STIBaseDocument, STIChildDocument, AnotherSTIChildDocument].each do |klass|
      klass.destroy
      Object.send :remove_const, klass.name.intern
    end
  end

  def add_validation_on_document_title
    Document.class_eval do
      validates_presence_of :title
    end
  end

  def remove_validation_on_document_title
    # Do nothing. The class is going to be reloaded on the next test.
  end

  def adapter_specific_update(instance, hash)
    response = instance.send :update, hash
  end
end
