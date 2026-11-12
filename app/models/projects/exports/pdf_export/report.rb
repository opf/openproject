# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Projects::Exports::PDFExport
  module Report
    def render_report(projects, info_map)
      projects.each do |project|
        write_optional_page_break
        write_project_detail(project, info_map[project.id])
      end
    end

    def write_project_detail(project, info_map_entry)
      info_map_entry[:page_number] = current_page_nr
      with_margin(styles.project_margins) do
        write_project_title(project, info_map_entry[:level_path])
        write_project_detail_content(project, select_fields)
      end
    end

    def write_project_title(project, level_path)
      text_style = styles.project_title
      with_margin(styles.project_title_margins) do
        link_target_at_current_y(project.id)
        level_string_width = write_project_level(level_path, text_style)
        pdf.indent(level_string_width) do
          pdf.formatted_text([text_style.merge({ text: project.name, link: url_helpers.project_url(project) })])
        end
      end
    end

    def write_project_level(level_path, text_style)
      return 0 if level_path.empty?

      level_string = "#{level_path.join('.')}. "
      level_string_width = measure_text_width(level_string, text_style)
      pdf.float { pdf.formatted_text([text_style.merge({ text: level_string })]) }
      level_string_width
    end

    def selects
      query.selects.reject { |s| s.is_a?(Queries::Selects::NotExistingSelect) }
    end

    def select_fields
      selects.map do |select|
        custom_field = select.is_a?(::Queries::Projects::Selects::CustomField) ? select.custom_field : nil
        { key: select.attribute, caption: select.caption, custom_field: }
      end
    end

    def can_view_attribute?(_project, attribute)
      attribute && %i[name favorited].exclude?(attribute)
    end
  end
end
