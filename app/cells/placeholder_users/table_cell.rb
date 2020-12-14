module PlaceholderUsers
  class TableCell < ::TableCell
    options :current_user # adds this option to those of the base class
    columns :lastname, :created_at

    def initial_sort
      [:id, :asc]
    end

    def headers
      columns.map do |name|
        [name.to_s, header_options(name)]
      end
    end

    def header_options(name)
      options = { caption: name == :lastname ? User.human_attribute_name(:name) : User.human_attribute_name(name) }

      options[:default_order] = 'desc' if desc_by_default.include? name

      options
    end

    def desc_by_default
      [:created_at]
    end
  end
end
