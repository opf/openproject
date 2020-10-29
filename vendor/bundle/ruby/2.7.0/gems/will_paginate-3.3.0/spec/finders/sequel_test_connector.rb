require 'sequel'

Symbol.class_eval do
  # Active Record calculations tries `as` on some objects but chokes when that
  # object was a Symbol and it gets a Sequel::SQL::AliasedExpression.
  undef as if method_defined? :as
end

db = Sequel.sqlite

db.create_table :cars do
  primary_key :id, :integer, :auto_increment => true
  column :name, :text
  column :notes, :text
end
