module LdapGroups
  module SynchronizedFilters
    class RowCell < ::RowCell
      include ::IconsHelper
      include ::PasswordHelper

      def synchronized_filter
        model
      end

      def name
        link_to synchronized_filter.name, ldap_groups_synchronized_filter_path(synchronized_filter)
      end

      def auth_source
        link_to synchronized_filter.auth_source.name, edit_auth_source_path(synchronized_filter.auth_source)
      end

      def groups
        synchronized_filter.groups.count
      end

      def button_links
        [
          edit_link,
          delete_link
        ]
      end

      def edit_link
        link_to I18n.t(:button_edit),
                { controller: table.target_controller, ldap_filter_id: model.id, action: :edit },
                class: 'icon icon-edit',
                title: t(:button_edit)
      end

      def delete_link
        link_to I18n.t(:button_delete),
                { controller: table.target_controller, ldap_filter_id: model.id, action: :destroy_info },
                class: 'icon icon-delete',
                title: t(:button_delete)
      end
    end
  end
end
