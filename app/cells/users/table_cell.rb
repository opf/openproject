module Users
  class TableCell < ::TableCell
    options :current_user # adds this option to those of the base class
    columns :login, :firstname, :lastname, :mail, :admin, :created_on, :last_login_on

    def initial_sort
      [:login, :asc]
    end

    def headers
      columns.map do |name|
        [name.to_s, header_options(name)]
      end
    end

    def header_options(name)
      options = { caption: User.human_attribute_name(name) }

      options[:default_order] = 'desc' if desc_by_default.include? name

      options
    end

    def desc_by_default
      [:admin, :created_on, :last_login_on]
    end
  end
end
