module GlobalRoles
  module AccessControlPatch
    def self.included(base)
      base.send(:extend, ClassMethods)

      base.class_eval do
        class << self
          alias_method :available_project_modules_without_no_global, :available_project_modules unless method_defined?(:available_project_modules_without_no_global)
          alias_method :available_project_modules, :available_project_modules_with_no_global
        end
      end
    end

    module ClassMethods
      def available_project_modules_with_no_global
        @available_project_modules = @permissions.reject{|p| p.global? }.collect(&:project_module).uniq.compact
        available_project_modules_without_no_global
      end

      def global_permissions
        @permissions.select {|p| p.global?}
      end
    end
  end
end

Redmine::AccessControl.send(:include, GlobalRoles::AccessControlPatch)