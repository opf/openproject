require 'acts_as_tree'

module ActiveRecord
  module Acts #:nodoc:
    module Tree
      include ::ActsAsTree

      def self.included(base)
        Kernel.warn "[DEPRECATION] The module ActiveRecord::Acts::Tree has moved to ActsAsTree"

        base.extend ::ActsAsTree::ClassMethods
      end
    end
  end
end
