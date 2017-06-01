module Members
  class TableCell < ::TableCell
    options :authorize_update, :available_roles
    columns :lastname, :firstname, :mail, :roles, :groups, :status

    def initial_sort
      [:lastname, :desc]
    end

    def headers
      columns.map do |name|
        [name.to_s, header_options(name)]
      end
    end

    def header_options(name)
      { caption: User.human_attribute_name(name) }
    end

    ##
    # Adjusts the order so that groups always come first.
    # Also implements sorting by group which is not trivial
    # due to it being a relation via 3 corners (member -> group_users -> users).
    def sort_collection(query, sort_clause, sort_columns)
      order_by = fix_roles_order(fix_groups_order(sort_clause))

      join_group(sort_columns, order_by_type_first(query)).order(order_by)
    end

    def order_by_type_first(query)
      query.order("users.type ASC")
    end

    def join_group(sort_columns, query)
      # we always join groups and group_users so we can later
      # filter by group in Members::UserFilterCell
      join_group_lastname query
    end

    def fix_groups_order(sort_clause)
      sort_clause.gsub /groups/, "groups.group_name"
    end

    def fix_roles_order(sort_clause)
      sort_clause.gsub /roles/, "roles.name"
    end

    ##
    # Joins the necessary columns to be able to sort by group name.
    # The subquery and renaming of the column is necessary to avoid naming conflicts
    # with the already joined users table.
    def join_group_lastname(query)
      query
        .joins(
          "
            LEFT JOIN group_users AS group_users
              ON group_users.user_id = members.user_id
            LEFT JOIN (SELECT id, lastname AS group_name FROM users) AS groups
              ON groups.id = group_users.group_id
          "
        )
    end
  end
end
