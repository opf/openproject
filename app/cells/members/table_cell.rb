module Members
  class TableCell < ::TableCell
    options :authorize_update, :available_roles, :is_filtered
    columns :name, :mail, :roles, :groups, :status
    sortable_columns :name, :mail, :status

    def initial_sort
      %i[name asc]
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

    def empty_row_message
      if is_filtered
        I18n.t :notice_no_principals_found
      else
        I18n.t :'members.index.no_results_title_text'
      end
    end
  end
end
