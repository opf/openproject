require_dependency "roles_helper"

module OpenProject::GlobalRoles::Patches
  module RolesHelperPatch
    def self.included(base)
      base.class_eval do

        def permissions_id permissions
          "permissions_" + permissions[0].hash.to_s
        end
      end
    end
  end
end

RolesHelper.send(:include, OpenProject::GlobalRoles::Patches::RolesHelperPatch)
