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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Project::PDFExport::Common::ProjectAttributes
  EMPTY_VALUE_PLACEHOLDER = "–"

  def write_project_detail_content(project, export_fields)
    return if export_fields.empty?

    if attributes_in_table?
      write_project_detail_content_tables(project, export_fields)
    else
      write_project_detail_content_list(project, export_fields)
    end
  end

  def write_project_detail_content_list(project, export_fields)
    export_fields.each do |field|
      write_field = process_field(project, field)
      next if write_field.nil?

      if write_field[:formattable]
        write_project_markdown(project, write_field[:value], write_field[:caption])
      else
        write_project_attribute(write_field[:value], write_field[:caption])
      end
    end
  end

  def write_project_detail_content_tables(project, export_fields)
    write_groups = collect_field_groups(project, export_fields)
    write_groups.each do |non_formattable_fields, formattable_field|
      write_project_fields(project, non_formattable_fields)
      write_project_markdown(project, formattable_field[:value], formattable_field[:caption]) if formattable_field
    end
  end

  def collect_field_groups(project, export_fields)
    field_groups = []
    non_formattable_fields_at_end = export_fields.inject([]) do |non_formattable_field_stack, field|
      write_field = process_field(project, field)
      if write_field.nil?
        non_formattable_field_stack
      elsif write_field[:formattable]
        field_groups.push([non_formattable_field_stack, write_field])
        []
      else
        non_formattable_field_stack + [write_field]
      end
    end
    field_groups << [non_formattable_fields_at_end, nil]
    field_groups
  end

  def process_field(project, field)
    if custom_field?(field)
      process_custom_attribute_field(project, field)
    elsif custom_comment?(field)
      process_custom_comment_field(project, field)
    elsif project_phase?(field)
      process_project_phase_field(project, field)
    elsif can_view_attribute?(project, field[:key])
      process_attribute_field(project, field)
    end
  end

  def write_project_fields(project, fields)
    table_entries = fields.filter_map do |field|
      table_entry(project, field[:caption], field[:key], field[:value])
    end

    write_table_entries(table_entries) if table_entries.any?
  end

  def write_table_entries(row_entries)
    return if row_entries.empty?

    rows = if attributes_table_4_column?
             0.step(row_entries.length - 1, 2).map do |i|
               row_entries[i] + (row_entries[i + 1] || ["", ""])
             end
           else
             row_entries
           end

    pdf.table(
      rows,
      column_widths: attributes_table_column_widths,
      cell_style: styles.project_attributes_table_cell.merge({ inline_format: true })
    )
  end

  def process_project_phase_field(project, field)
    return unless user_can_view_project_phases?(project)

    value = project_phase_value(project, field)
    return if value.nil?

    field.merge(value:)
  end

  def user_can_view_project_phases?(project)
    User.current.allowed_in_project?(:view_project_phases, project) && project.phases.active.any?
  end

  def project_phase_value(project, field)
    project_phase_definition = Project::PhaseDefinition
                                 .find_by(id: field[:key][/\Aproject_phase_(\d+)\z/, 1])
    return nil if project_phase_definition.nil?

    phase = project.phases.active.find_by(definition: project_phase_definition)
    return nil if phase.nil?

    format_phase_value(phase)
  end

  def format_phase_value(phase)
    start = if phase.start_date.present?
              format_date(phase.start_date)
            else
              I18n.t("js.label_no_start_date")
            end

    finish = if phase.finish_date.present?
               format_date(phase.finish_date)
             else
               I18n.t("js.label_no_due_date")
             end

    "#{start} - #{finish}"
  end

  def process_custom_attribute_field(project, field)
    if field[:custom_field].formattable?
      custom_value = project.custom_value_for(field[:custom_field])
      field.merge(value: custom_value&.value, formattable: true)
    else
      field.merge(value: format_attribute(project, field[:key], :pdf))
    end
  end

  def process_custom_comment_field(project, field)
    field.merge(value: format_attribute(project, field[:key], :pdf))
  end

  def process_attribute_field(project, field)
    field.merge(value: format_attribute(project, field[:key], :pdf), formattable: attribute_formattable?(field[:key]))
  end

  def attribute_formattable?(attribute)
    %i[description status_explanation].include? attribute
  end

  def custom_field?(field)
    field[:key]&.start_with?("cf_")
  end

  def custom_comment?(field)
    field[:key]&.start_with?("cfc_")
  end

  def project_phase?(field)
    field[:key]&.start_with?("project_phase_")
  end

  def custom_field_active_in_project?(project, custom_field)
    custom_field.is_for_all? ||
      project.project_custom_field_project_mappings.exists?(custom_field_id: custom_field.id)
  end

  def write_project_attribute(value, caption)
    if value.blank?
      return if hide_empty_attributes?

      value = EMPTY_VALUE_PLACEHOLDER
    end
    write_optional_page_break
    write_markdown_label(caption)
    with_margin(styles.project_markdown_margins) do
      style = styles.project_attribute_value
      formatted = if value.is_a?(::Exports::Formatters::LinkFormatter)
                    { link: value.to_s, text: value.to_s }
                  else
                    { text: value.to_s }
                  end
      pdf.formatted_text([style.merge(formatted)], style)
    end
  end

  def write_project_markdown(project, value, caption)
    if value.blank?
      return if hide_empty_attributes?

      value = EMPTY_VALUE_PLACEHOLDER
    end
    write_optional_page_break
    write_markdown_label(caption) if caption
    with_margin(styles.project_markdown_margins) do
      write_markdown!(
        apply_markdown_field_macros(value, { project:, user: User.current }),
        styles.project_markdown_styling_yml
      )
    end
  end

  def write_markdown_label(caption)
    with_margin(styles.project_markdown_label_margins) do
      style = styles.project_markdown_label
      pdf.formatted_text([style.merge({ text: caption })], style)
    end
  end

  def attributes_in_table?
    true
  end

  def attributes_table_4_column?
    false
  end

  def attributes_table_column_widths
    widths = if attributes_table_4_column?
               # label | value | label | value
               [1.5, 2.0, 1.5, 2.0]
             else
               # label | value
               [1.0, 3.0]
             end
    ratio = pdf.bounds.width / widths.sum
    widths.map { |w| w * ratio }
  end

  def table_entry(project, caption, value_key, value)
    if value.blank?
      return nil if hide_empty_attributes?

      value = EMPTY_VALUE_PLACEHOLDER
    end

    if value.is_a?(::Exports::Formatters::LinkFormatter)
      value = get_cf_link_cell(value)
    elsif value_key == :id
      value = make_link_href_cell(url_helpers.project_url(project), value)
    end
    [
      { content: caption }.merge(styles.project_attributes_table_label_cell),
      value || ""
    ]
  end

  def write_formattable_attribute(project, attribute, caption)
    write_project_markdown project, project.try(attribute), caption
  end

  def write_formattable_custom_field(project, custom_field)
    custom_field_value = project.custom_value_for(custom_field)
    write_project_markdown project, custom_field_value.value, custom_field.name
  end
end
