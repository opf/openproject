module Members
  class UserFilterCell < ::UserFilterCell
    class << self
      def filter_name_condition
        super.gsub /lastname|firstname|mail/, "users.\\0"
      end

      def filter_name_columns
        [:lastname, :firstname, :mail]
      end

      def filter_status_condition
        super.sub /status/, "users.\\0"
      end

      def filter_group_condition
        # we want to list both the filtered group itself if a member (left of OR)
        # and users of that group (right of OR)
        super.sub /group_id/, "users.id = :group_id OR group_users.\\0"
      end

      def join_group_users(query)
        query # it will be joined by the table already
      end

      def filter_role_condition
        super.sub /role_id/, "member_roles.\\0"
      end

      def join_role(query)
        query # it will be joined by the table already
      end
    end
  end
end
