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
  REPORT_HEADER_COLOR = "414D5F"
  STATUS_COLORS = {
    "on_track" => %w[E8F4EC 21663C],
    "at_risk" => %w[FFF3D5 785004],
    "off_track" => %w[FBE8EA 8C2330]
  }.freeze

  def self.key = :status_report_export_pdf

  def with_cover? = false

  def with_toc? = false

  def hide_empty_attributes? = true

  def write_section_title(text)
    with_margin(styles.section_title_margins) do
      style = styles.section_title.merge(size: 14, color: "1F2328")
      pdf.formatted_text([style.merge(text:)], style)
    end
  end

  def write_artefact_title
    write_header_text(project.name, size: 13, bold: true)
    pdf.move_down 9
    write_horizontal_line(pdf.cursor, 0.65, "D3DEE3")
    pdf.move_down 15
    write_header_text(heading, size: 10)
  end

  def write_artefact_heading
    pdf.move_down 6
    write_header_text(work_package.subject, size: 28, bold: true)
    if report_period.present?
      pdf.move_down 8
      write_header_text(report_period, size: 10)
    end
    pdf.move_down 16
    write_status_card
  end

  def write_artefact_description
    return if work_package.description.blank?

    write_section_title(report_label(:status_summary))
    super
  end

  def write_artefact
    write_project_details
    write_report_details
    form_configuration(work_package).groups.grep(WorkPackage::Exports::FormConfiguration::QueryGroup).each do |group|
      write_query_group(group)
    end
  end

  private

  def write_header_text(text, size:, bold: false)
    style = { size:, color: REPORT_HEADER_COLOR, styles: bold ? [:bold] : [] }
    pdf.formatted_text([style.merge(text: text.to_s)])
  end

  def report_period
    [work_package.start_date, work_package.due_date].compact.uniq.map { |date| format_date(date) }.join(" – ")
  end

  def write_status_card
    return if project.status_code.blank?

    background, foreground = STATUS_COLORS.fetch(project.status_code, %w[F0F0F0 414D5F])
    pdf.table([[status_card_content(foreground)]],
              column_widths: [pdf.bounds.width / 3],
              cell_style: { background_color: background, borders: [], padding: 10, inline_format: true })
    pdf.move_down 12
  end

  def status_card_content(color)
    label = escape_tags(report_label(:project_status))
    value = escape_tags(I18n.t("activerecord.attributes.project.status_codes.#{project.status_code}"))
    %(<font color="#{color}"><b>#{label}</b><br/><font size="18"><b>#{value}</b></font></font>)
  end

  def write_project_details
    write_optional_page_break
    write_section_title(report_label(:project_attributes))
    write_project_description
    write_project_attribute(project.identifier, Project.human_attribute_name(:identifier))
    return unless current_user.allowed_in_project?(:view_project_attributes, project)

    fields = collect_project_attributes_data.flat_map { |section| section[:fields] }
    write_project_detail_content(project, fields)
  end

  def write_project_description
    return if project.description.blank?

    write_project_markdown(project, project.description, nil)
  end

  def write_report_details
    write_optional_page_break
    write_section_title(report_label(:report_details))
    write_project_attribute(work_package.status.name, report_label(:workflow_status))
    report_attribute_parts.each { |part| write_report_attribute_part(part) }
  end

  def write_report_attribute_part(part)
    case part
    when WorkPackage::Exports::FormConfiguration::AttributesPart
      write_populated_report_attributes(part)
    when WorkPackage::Exports::FormConfiguration::LongTextPart
      write_long_text_custom_field!(work_package, part.markdown, part.label) if part.markdown.present?
    end
  end

  def report_attribute_parts
    form_configuration(work_package).groups.grep(WorkPackage::Exports::FormConfiguration::AttributeGroup).flat_map(&:parts)
  end

  def write_populated_report_attributes(part)
    fields = attribute_entries_with_values(part, work_package).select do |field|
      field[:name].to_s.start_with?("cf_") && field[:value].present?
    end
    write_attributes_table(form_config_group_to_column_entries_rows(fields))
  end

  def report_label(key)
    I18n.t(key, scope: "pdf_generator.template_status_report")
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

  def build_header_row(columns)
    header_style = styles.wp_table_header_cell.merge(background_color: "F0F0F0", borders: [], padding: [5, 6])
    columns.map { |column| pdf.make_cell(column.caption || "", header_style) }
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
