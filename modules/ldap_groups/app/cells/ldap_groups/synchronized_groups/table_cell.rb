
module LdapGroups
  module SynchronizedGroups
    class TableCell < ::TableCell
      columns :entry, :auth_source, :group, :users

      def initial_sort
        %i[id asc]
      end

      def target_controller
        'ldap_groups/synchronized_groups'
      end

      def sortable?
        false
      end

      def inline_create_link
        link_to({ controller: target_controller, action: :new },
                class: 'budget-add-row wp-inline-create--add-link',
                title: I18n.t('ldap_groups.synchronized_groups.add_new')) do
          op_icon('icon icon-add')
        end
      end

      def empty_row_message
        I18n.t 'ldap_groups.synchronized_groups.no_results'
      end

      def headers
        [
            ['entry', caption: ::LdapGroups::SynchronizedGroup.human_attribute_name('entry')],
            ['auth_source', caption: ::LdapGroups::SynchronizedGroup.human_attribute_name('auth_source')],
            ['group', caption: I18n.t(:label_group)],
            ['users', caption: I18n.t(:label_user_plural)],
        ]
      end
    end
  end
end