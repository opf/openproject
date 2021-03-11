module Projects
  class RowCell < ::RowCell
    include ProjectsHelper
    include ProjectStatusHelper
    include ApplicationHelper
    include ::Redmine::I18n

    def project
      model.first
    end

    def level
      model.last
    end

    # Hierarchy cell is just a placeholder
    def hierarchy
      ''
    end

    def column_value(column)
      if column.to_s.start_with? 'cf_'
        escaped(custom_field_column(column))
      else
        super
      end
    end

    def custom_field_column(column)
      cf = custom_field(column)
      custom_value = project.custom_value_for(cf).formatted_value

      if cf.field_format == 'text'
        custom_value.html_safe
      else
        custom_value
      end
    end

    def created_at
      format_date(project.created_at)
    end

    def latest_activity_at
      format_date(project.latest_activity_at)
    end

    def required_disk_space
      return '' unless project.required_disk_space.to_i > 0

      number_to_human_size(project.required_disk_space, precision: 2)
    end

    def name
      content = content_tag(:i, '', class: "projects-table--hierarchy-icon")

      if project.archived?
        content << ' '
        content << content_tag(:span, I18n.t('project.archive.archived'), class: 'archived-label')
      end

      content << ' '
      content << link_to_project(project, {}, {}, false)
      content
    end

    def project_status
      content = ''.html_safe

      if project.status.try(:code)
        classes = project_status_css_class(project.status)
        content << content_tag(:span, '', class: "project-status--bulb -inline #{classes}")
        content << content_tag(:span, project_status_name(project.status), class: "project-status--name #{classes}")
      end

      content
    end

    def status_explanation
      if project.status.try(:explanation)
        content_tag :div, format_text(project.status.explanation), class: 'wiki'
      end
    end

    def public
      checked_image project.public?
    end

    def row_css_class
      classes = %w[basics context-menu--reveal]
      classes << project_css_classes
      classes << row_css_level_classes

      if params[:expand] == 'all' && project.description.present?
        classes << ' -no-highlighting -expanded'
      end

      classes.join(" ")
    end

    def row_css_level_classes
      if level > 0
        "idnt idnt-#{level}"
      else
        ""
      end
    end

    def project_css_classes
      s = ' project '

      s << ' root' if project.root?
      s << ' child' if project.child?
      s << (project.leaf? ? ' leaf' : ' parent')

      s
    end

    def column_css_class(column)
      "#{super} #{additional_css_class(column)}"
    end

    def custom_field(name)
      table.project_custom_fields.fetch(name)
    end

    def additional_css_class(column)
      case column
      when :name
        "project--hierarchy #{project.archived? ? 'archived' : ''}"
      when :status_explanation
        "-no-ellipsis"
      when /\Acf_/
        cf = custom_field(column)
        "format-#{cf.field_format}"
      end
    end
  end
end
