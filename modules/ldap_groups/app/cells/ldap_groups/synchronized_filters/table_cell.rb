
module LdapGroups
  module SynchronizedFilters
    class TableCell < ::TableCell
      columns :name, :auth_source, :groups

      def initial_sort
        %i[id asc]
      end

      def target_controller
        'ldap_groups/synchronized_filters'
      end

      def sortable?
        false
      end

      def inline_create_link
        link_to({ controller: target_controller, action: :new },
                class: 'budget-add-row wp-inline-create--add-link',
                title: I18n.t('ldap_groups.synchronized_filters.add_new')) do
          op_icon('icon icon-add')
        end
      end

      def headers
        [
            ['name', caption: ::LdapGroups::SynchronizedFilter.human_attribute_name('name')],
            ['auth_source', caption: ::LdapGroups::SynchronizedFilter.human_attribute_name('auth_source')],
            ['groups', caption: I18n.t('ldap_groups.synchronized_filters.plural')]
        ]
      end
    end
  end
end