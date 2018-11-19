module OpenProject
  module LdapGroups
    require "open_project/ldap_groups/engine"

    class << self

      def settings
        Setting.plugin_openproject_ldap_groups
      end

      def group_base
        settings[:group_base]
      end

      def group_key
        settings[:group_key]
      end

      def group_dn(value)
        "#{group_key}=#{value},#{group_base}"
      end
    end
  end
end
