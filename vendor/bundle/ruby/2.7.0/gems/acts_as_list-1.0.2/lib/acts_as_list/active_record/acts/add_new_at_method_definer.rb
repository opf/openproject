# frozen_string_literal: true

module ActiveRecord::Acts::List::AddNewAtMethodDefiner #:nodoc:
  def self.call(caller_class, add_new_at)
    caller_class.class_eval do
      define_method :add_new_at do
        add_new_at
      end
    end
  end
end
