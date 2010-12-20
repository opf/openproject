module GlobalRoles
  module AccessControlPatch
    def self.included(base)
      base.send(:extend, ClassMethods)

      base.class_eval do
        def self.global_permissions
          @global_permissions ||= @permissions.select {|p| p.global?}
        end

        class << self
          alias_method :available_project_modules_without_no_global, :available_project_modules unless method_defined?(:available_project_modules_without_no_global)
          alias_method :available_project_modules, :available_project_modules_with_no_global
        end
      end
    end

    module ClassMethods
      def available_project_modules_with_no_global
        @available_project_modules ||= @permissions.delete_if{|p| p.global? }.collect(&:project_module).uniq.compact
        available_project_modules_without_no_global
      end
    end
  end
end

Redmine::AccessControl.send(:include, GlobalRoles::AccessControlPatch)