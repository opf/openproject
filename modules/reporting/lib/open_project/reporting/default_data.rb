module OpenProject
  module Reporting
    module DefaultData
      module_function

      def load!
        restrict_project_admin_permissions!
      end

      ##
      # The Project Admin role is assigned all possible permission in
      # the core's `roles.rb` seed. Here we remove those permissions
      # which should not be assigned by default.
      def restrict_project_admin_permissions!
        role = project_admin_role or raise 'Project admin role not found'

        role.remove_permission! *restricted_project_admin_permissions
      end

      def project_admin_role
        Role.find_by name: I18n.t(:default_role_project_admin)
      end

      def restricted_project_admin_permissions
        [
          :save_cost_reports,
          :save_private_cost_reports
        ]
      end
    end
  end
end
