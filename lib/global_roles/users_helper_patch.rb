require_dependency 'users_helper'

module GlobalRoles
  module UsersHelperPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        alias_method_chain :user_settings_tabs, :global_roles
      end
    end

    module InstanceMethods

      def user_settings_tabs_with_global_roles
        tabs = user_settings_tabs_without_global_roles
        tabs << {:name => 'global_roles', :partial => 'users/global_roles', :label => "global_roles"}
        tabs
      end


    end
  end
end

UsersHelper.send(:include, GlobalRoles::UsersHelperPatch)
