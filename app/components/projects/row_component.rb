# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Projects
  class RowComponent < ::RowComponent
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
        custom_field_column(column)
      else
        super
      end
    end

    def custom_field_column(column)
      cf = custom_field(column)
      custom_value = project.formatted_custom_value_for(cf)

      if cf.field_format == 'text'
        custom_value.html_safe # rubocop:disable Rails/OutputSafety
      elsif custom_value.is_a?(Array)
        safe_join(Array(custom_value).compact_blank, ', ')
      else
        custom_value
      end
    end

    def created_at
      helpers.format_date(project.created_at)
    end

    def latest_activity_at
      helpers.format_date(project.latest_activity_at)
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
      content << helpers.link_to_project(project, {}, {}, false)
      content
    end

    def project_status
      content = ''.html_safe

      status_code = project.status_code

      if status_code
        classes = helpers.project_status_css_class(status_code)
        content << content_tag(:span, '', class: "project-status--bulb -inline #{classes}")
        content << content_tag(:span, helpers.project_status_name(status_code), class: "project-status--name #{classes}")
      end

      content
    end

    def status_explanation
      if project.status_explanation
        content_tag :div, helpers.format_text(project.status_explanation), class: 'wiki'
      end
    end

    def public
      helpers.checked_image project.public?
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
      s = ' project '.html_safe

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
        formattable = cf.field_format == 'text' ? ' -no-ellipsis' : ''
        "format-#{cf.field_format}#{formattable}"
      end
    end
  end
end
