module LdapGroups
  module SynchronizedGroups
    class RowCell < ::RowCell
      include ::IconsHelper
      include ::PasswordHelper

      def synchronized_group
        model
      end

      def entry
        link_to synchronized_group.entry, ldap_groups_synchronized_group_path(synchronized_group)
      end

      def auth_source
        link_to synchronized_group.auth_source.name, edit_auth_source_path(synchronized_group.auth_source)
      end

      def group
        link_to synchronized_group.group.name, edit_group_path(synchronized_group.group)
      end

      def users
        synchronized_group.users.count
      end

      def button_links
        [delete_link]
      end

      def delete_link
        link_to I18n.t(:button_delete),
                controller: table.target_controller, ldap_group_id: model.id, action: :destroy_info
      end
    end
  end
end