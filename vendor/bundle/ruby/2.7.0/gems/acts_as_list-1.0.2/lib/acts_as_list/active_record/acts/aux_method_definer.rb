# frozen_string_literal: true

module ActiveRecord::Acts::List::AuxMethodDefiner #:nodoc:
  def self.call(caller_class)
    caller_class.class_eval do
      define_method :acts_as_list_class do
        caller_class
      end
    end
  end
end
