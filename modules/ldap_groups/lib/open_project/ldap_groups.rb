module OpenProject
  module LdapGroups
    require "open_project/ldap_groups/engine"

    class << self

      def settings
        Setting.plugin_openproject_ldap_groups
      end

      def group_dn(value)
        "#{settings[:group_key]}=#{value},#{settings[:group_base]}"
      end
    end
  end
end
