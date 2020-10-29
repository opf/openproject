# frozen_string_literal: true

module ActiveRecord::Acts::List::TopOfListMethodDefiner #:nodoc:
  def self.call(caller_class, top_of_list)
    caller_class.class_eval do
      define_singleton_method :acts_as_list_top do
        top_of_list.to_i
      end

      define_method :acts_as_list_top do
        top_of_list.to_i
      end
    end
  end
end
