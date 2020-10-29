gem 'activerecord'
require 'active_record'
require "stringex"
# Reload adapters to make sure ActsAsUrl sees the ORM
Stringex::ActsAsUrl::Adapter.load_available

puts "-------------------------------------------------"
puts "Running ActsAsUrl tests with ActiveRecord adapter"
puts "-------------------------------------------------"

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

ActiveRecord::Migration.verbose = false
ActiveRecord::Schema.define do
  create_table :documents, force: true do |t|
    t.string :title, :other, :another, :url
  end

  create_table :sti_base_documents, force: true do |t|
    t.string :title, :other, :another, :url, :type
  end
end
ActiveRecord::Migration.verbose = true

class Document < ActiveRecord::Base
  acts_as_url :title
end

class STIBaseDocument < ActiveRecord::Base
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
