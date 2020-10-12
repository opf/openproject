module LdapGroups
  module SynchronizedGroups
    class RowCell < ::RowCell
      include ::IconsHelper
      include ::PasswordHelper

      def synchronized_group
        model
      end

      def dn
        link_to synchronized_group.dn, ldap_groups_synchronized_group_path(synchronized_group)
      end

      def auth_source
        link_to synchronized_group.auth_source.name, edit_auth_source_path(synchronized_group.auth_source)
      end

      def group
        link_to synchronized_group.group.name, edit_group_path(synchronized_group.group)
      end

      def users
        synchronized_group.users.size
      end

      def button_links
        [delete_link].compact
      end

      def delete_link
        return if table.options[:deletable] == false

        link_to I18n.t(:button_delete),
                { controller: table.target_controller, ldap_group_id: model.id, action: :destroy_info },
                class: 'icon icon-delete',
                title: t(:button_delete)
      end
    end
  end
end
