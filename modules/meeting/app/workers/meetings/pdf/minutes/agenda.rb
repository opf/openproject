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

module Meetings::PDF::Minutes::Agenda
  include Meetings::PDF::Common::Agenda

  def write_backlog
    return if meeting.backlog.blank? || meeting.backlog.agenda_items.empty?

    write_heading(meeting.recurring? ? I18n.t("label_series_backlog") : I18n.t("label_agenda_backlog"))
    write_agenda_items(meeting.backlog)
  end

  def write_section(section, index)
    write_optional_page_break
    write_section_title(section, index)
    write_agenda_items(section, index)
  end

  def write_section_title(section, index)
    margins = styles.agenda_section_title_table_margins
    with_vertical_margin(margins) do
      write_section_title_table(section, index)
    end
  end

  def write_section_title_table(section, index)
    pdf.table(
      [[
        { content: "#{index + 1}." },
        { content: format_agenda_section_title_cell(section) }
      ]],
      width: pdf.bounds.width,
      column_widths: [40, pdf.bounds.width - 40],
      cell_style: { inline_format: true }.merge(styles.agenda_section_title_cell)
    )
  end

  def format_agenda_section_title_cell(section)
    content = [prawn_table_cell_inline_formatting_data(section_title(section), styles.agenda_section_title)]
    if section.agenda_items_sum_duration_in_minutes > 0
      content.push(
        prawn_table_cell_inline_formatting_data(
          format_duration(section.agenda_items_sum_duration_in_minutes),
          styles.agenda_section_subtitle
        )
      )
    end
    content.join("  ")
  end

  def write_agenda_items(section, section_index)
    section.agenda_items.each_with_index do |item, index|
      write_optional_page_break
      with_vertical_margin(styles.agenda_item_margins) do
        write_agenda_item(item, section_index, index)
      end
    end
  end

  def write_agenda_item(agenda_item, section_index, index)
    case agenda_item.item_type.to_sym
    when :simple
      write_agenda_title_item_simple(agenda_item, section_index, index)
    when :work_package
      write_agenda_title_item_wp(agenda_item, section_index, index)
    end
    write_notes(agenda_item)
    write_outcomes(agenda_item) if with_outcomes?
  end

  def write_agenda_item_title(title, section_index, index)
    with_vertical_margin(styles.agenda_item_title_margins) do
      pdf.table(
        [[
          { content: "#{section_index + 1}.#{index + 1}." },
          { content: title }
        ]],
        width: pdf.bounds.width,
        column_widths: [40, pdf.bounds.width - 40],
        cell_style: { inline_format: true }.merge(styles.agenda_item_title_cell)
      )
    end
  end

  def format_agenda_item_cell(text, duration, user)
    content = [format_agenda_item_title(text)]
    content.push(format_agenda_item_subtitle(format_duration(duration))) if duration > 0
    content.push(format_agenda_item_subtitle(user.name)) unless user.nil?
    content.join("  ")
  end

  def write_agenda_title_item_wp(agenda_item, section_index, index)
    write_agenda_item_title(agenda_wp_title_row(agenda_item), section_index, index)
  end

  def write_agenda_title_item_simple(agenda_item, section_index, index)
    write_agenda_item_title(agenda_item.title, section_index, index)
  end

  def write_notes(agenda_item)
    return if agenda_item.notes.blank?

    with_vertical_margin(styles.notes_markdown_margins) do
      write_markdown!(
        apply_markdown_field_macros(agenda_item.notes, { project: meeting.project, user: User.current }),
        styles.notes_markdown_styling_yml
      )
    end
  end
end
