module Members
  class TableCell < ::TableCell
    options :authorize_update, :available_roles
    columns :lastname, :firstname, :mail, :roles, :groups, :status
    sortable_columns :lastname, :firstname, :mail

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
    # Adjusts the order so that users are joined to support
    # sorting by their attributes
    def sort_collection(query, sort_clause, sort_columns)
      super(join_users(query), sort_clause, sort_columns)
    end

    def join_users(query)
      query.joins(:principal).references(:principal)
    end
  end
end
