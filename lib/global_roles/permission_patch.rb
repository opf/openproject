module GlobalRoles
  module PermissionPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        alias_method_chain :initialize, :global_option
      end
    end

    module InstanceMethods
      def initialize_with_global_option(name, hash, options)
        @global = options[:global] || false
        initialize_without_global_option(name, hash, options)
      end

      def global?
        @global || global_require
      end

      def global=(bool)
        @global = bool
      end

      private

      def global_require
        @require && @require == :global
      end
    end
  end
end

Redmine::AccessControl::Permission.send(:include, GlobalRoles::PermissionPatch)