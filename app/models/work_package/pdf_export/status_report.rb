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

class WorkPackage::PDFExport::StatusReport < WorkPackage::PDFExport::Artefact
  def self.key = :status_report_export_pdf

  def with_cover? = false

  def with_toc? = false

  def write_artefact
    write_core_project_attributes
    write_artefact_project_attributes if current_user.allowed_in_project?(:view_project_attributes, project)
    write_artefact_wp_attributes
  end

  private

  def write_core_project_attributes
    write_optional_page_break
    write_section_title(I18n.t("pdf_generator.template_status_report.project_attributes"))
    core_project_attributes.each do |attribute, value|
      write_project_attribute(value, Project.human_attribute_name(attribute))
    end
    write_project_description
  end

  def core_project_attributes
    { name: project.name, identifier: project.identifier, status_code: project_status }
  end

  def write_project_description
    return if project.description.blank?

    write_project_markdown(project, project.description, Project.human_attribute_name(:description))
  end

  def project_status
    return if project.status_code.blank?

    I18n.t("activerecord.attributes.project.status_codes.#{project.status_code}")
  end

  def write_query_group(group)
    write_group_title(group)
    related = group.work_packages.select { |candidate| related_work_package_ids.include?(candidate.id) }
    if related.empty?
      write_inline_hint(I18n.t("pdf_generator.template_status_report.no_related_work_packages"))
    else
      write_related_table(group.query, related)
    end
  end

  def write_related_table(query, related)
    columns = limit_table_columns_objects(query)
    return if columns.empty?

    rows = [build_header_row(columns), *related.map { |candidate| build_table_row(candidate, columns) }]
    with_margin(styles.wp_table_margins) do
      pdf_table_auto_widths(rows, table_column_widths(columns), wp_table_options)
    end
  rescue Prawn::Errors::CannotFit
    write_inline_error("[#{I18n.t('export.errors.embedded_table_with_too_many_columns')}]")
  end

  def related_work_package_ids
    @related_work_package_ids ||= work_package.relations
                                              .visible(current_user)
                                              .pluck(:from_id, :to_id)
                                              .flatten
                                              .to_set
                                              .delete(work_package.id)
  end
end
