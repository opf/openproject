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

module Meetings::PDF::Default::Agenda
  include Meetings::PDF::Common::Agenda

  def write_backlog
    return if meeting.backlog.blank? || meeting.backlog.agenda_items.empty?

    write_hr
    write_heading(meeting.recurring? ? I18n.t("label_series_backlog") : I18n.t("label_agenda_backlog"))
    write_agenda_items(meeting.backlog)
  end

  def write_section(section, section_index)
    write_optional_page_break
    unless section.title.blank? && section_index == 0 && meeting.sections.one?
      write_section_title(section, section_index)
    end
    write_agenda_items(section)
  end

  def write_section_title(section, section_index)
    margins = styles.agenda_section_title_table_margins
    margins = margins.merge({ top_margin: 0 }) if section_index == 0
    with_vertical_margin(margins) do
      pdf.table(
        [[{ content: format_agenda_section_title_cell(section) }]],
        width: pdf.bounds.width,
        cell_style: { inline_format: true }.merge(styles.agenda_section_title_cell)
      )
    end
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

  def write_agenda_items(section)
    section.ordered_agenda_items.each_with_index do |item, index|
      write_agenda_item_hr if index > 0
      write_optional_page_break
      write_agenda_item(item)
    end
  end

  def write_agenda_item_hr
    hr_style = styles.agenda_item_hr
    with_vertical_margin(styles.agenda_item_hr_margins) do
      write_horizontal_line(
        pdf.cursor,
        hr_style[:height],
        hr_style[:color],
        left_padding: styles.agenda_item_indent
      )
    end
  end

  def write_agenda_item(agenda_item)
    case agenda_item.item_type.to_sym
    when :simple
      write_agenda_title_item_simple(agenda_item)
    when :work_package
      write_agenda_title_item_wp(agenda_item)
    end
    write_notes(agenda_item)
    write_outcomes(agenda_item) if with_outcomes?
  end

  def write_agenda_item_title(title, duration, user)
    with_vertical_margin(styles.agenda_item_title_margins) do
      pdf.table(
        [[{ content: format_agenda_item_cell(title, duration, user) }]],
        width: pdf.bounds.width,
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

  def write_agenda_title_item_wp(agenda_item)
    write_agenda_item_title(
      agenda_wp_title_row(agenda_item),
      agenda_item.duration_in_minutes || 0,
      agenda_item.presenter
    )
  end

  def write_agenda_title_item_simple(agenda_item)
    write_agenda_item_title(agenda_item.title, agenda_item.duration_in_minutes || 0, agenda_item.presenter)
  end

  def write_notes(agenda_item)
    return if agenda_item.notes.blank?

    pdf.indent(styles.agenda_item_indent) do
      write_markdown!(
        apply_markdown_field_macros(agenda_item.notes, { project: meeting.project, user: User.current }),
        styles.notes_markdown_styling_yml
      )
    end
  end
end
