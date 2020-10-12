module LdapGroups
  module Memberships
    class RowCell < ::RowCell
      include ::OpenProject::ObjectLinking

      def membership
        model
      end

      def user
        link_to_user(membership.user)
      end

      def added
        format_date(membership.updated_at)
      end
    end
  end
end

