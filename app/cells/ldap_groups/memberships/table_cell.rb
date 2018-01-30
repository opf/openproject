module LdapGroups
  module Memberships
    class TableCell < ::TableCell
      columns :user, :added

      def initial_sort
        %i[created_at asc]
      end

      def sortable?
        false
      end

      def empty_row_message
        I18n.t 'ldap_groups.synchronized_groups.no_members'
      end

      def headers
        [
            ['user', caption: ::LdapGroups::Membership.human_attribute_name('user')],
            ['added', caption: ::LdapGroups::Membership.human_attribute_name('created_on')]
        ]
      end
    end
  end
end
