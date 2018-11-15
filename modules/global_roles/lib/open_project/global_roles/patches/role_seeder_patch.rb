module OpenProject::GlobalRoles::Patches
  module RoleSeederPatch
    def self.included(base)
      base.prepend InstanceMethods
    end

    module InstanceMethods
      def roles
        super + [project_creator]
      end

      def project_creator
        { name: I18n.t(:'seeders.default_role_project_creator'),
          position: 6,
          permissions: [:add_project],
          type: 'GlobalRole'
        }
      end
    end
  end
end
