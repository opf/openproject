module Projects
  class TableCell < ::TableCell
    include ProjectsHelper

    options :params # We read collapsed state from params
    options :current_user # adds this option to those of the base class

    def initial_sort
      %i[lft asc]
    end

    def table_id
      'project-table'
    end

    ##
    # The project sort by is handled differently
    def build_sort_header(column, options)
      projects_sort_header_tag(column, options.merge(param: :json))
    end

    # We don't return the project row
    # but the [project, level] array from the helper
    def rows
      @rows ||= to_enum(:projects_with_levels_order_sensitive, model).to_a
    end

    def initialize_sorted_model
      sort_clear

      orders = options[:orders]
      sort_init orders
      sort_update orders.map(&:first)
    end

    def paginated?
      true
    end

    def deactivate_class_on_lft_sort
      if sorted_by_lft?
        '-inactive'
      end
    end

    def href_only_when_not_sort_lft
      unless sorted_by_lft?
        projects_path(sortBy: JSON::dump([['lft', 'asc']]))
      end
    end

    def all_columns
      @all_columns ||= begin
        [
          [:hierarchy, { builtin: true }],
          [:name, { builtin: true, caption: Project.human_attribute_name(:name) }],
          [:project_status, { caption: Project.human_attribute_name(:status) }],
          [:status_explanation, { caption: Projects::Status.human_attribute_name(:explanation) }],
          [:public, { caption: Project.human_attribute_name(:public) }],
          *custom_field_columns,
          *admin_columns
        ]
      end
    end

    def headers
      all_columns
        .select do |name, options|
        options[:builtin] || Setting.enabled_projects_columns.include?(name.to_s)
      end
    end

    def sortable_column?(_column)
      true
    end

    def columns
      @columns ||= headers.map(&:first)
    end

    def admin_columns
      return [] unless current_user.admin?

      [
        [:created_at, { caption: Project.human_attribute_name(:created_at) }],
        [:latest_activity_at, { caption: Project.human_attribute_name(:latest_activity_at) }],
        [:required_disk_space, { caption: I18n.t(:label_required_disk_storage) }]
      ]
    end

    def custom_field_columns
      project_custom_fields.values.map do |custom_field|
        [:"cf_#{custom_field.id}", { caption: custom_field.name, custom_field: true }]
      end
    end

    def project_custom_fields
      @project_custom_fields ||= begin
        fields =
          if EnterpriseToken.allows_to?(:custom_fields_in_projects_list)
            ProjectCustomField.visible(current_user).order(:position)
          else
            ProjectCustomField.none
          end

        fields
          .map { |cf| [:"cf_#{cf.id}", cf] }
          .to_h
      end
    end
  end
end
