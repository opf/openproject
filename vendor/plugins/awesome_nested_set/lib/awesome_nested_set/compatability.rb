#-- encoding: UTF-8
# Rails <2.x doesn't define #except
class Hash #:nodoc:
  # Returns a new hash without the given keys.
  def except(*keys)
    clone.except!(*keys)
  end unless method_defined?(:except)

  # Replaces the hash without the given keys.
  def except!(*keys)
    keys.map! { |key| convert_key(key) } if respond_to?(:convert_key)
    keys.each { |key| delete(key) }
    self
  end unless method_defined?(:except!)
end

# NamedScope is new to Rails 2.1
unless defined? ActiveRecord::NamedScope
  require 'awesome_nested_set/named_scope'
  ActiveRecord::Base.class_eval do
    include CollectiveIdea::NamedScope
  end
end

# Rails 1.2.x doesn't define #quoted_table_name
class ActiveRecord::Base  #:nodoc:
  def self.quoted_table_name
    self.connection.quote_column_name(self.table_name)
  end unless methods.include?('quoted_table_name')
end