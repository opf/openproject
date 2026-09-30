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

module Meetings::PDF::Default::Participants
  def write_participants
    return if participants.empty?

    write_heading(participants_title)
    write_participants_table
  end

  def write_participants_table
    columns_count = [participants.size, 3].min

    rows = participants_table_rows(columns_count)
    with_vertical_margin(styles.participants_margins) do
      pdf.table(
        rows,
        column_widths: participants_table_column_widths(columns_count),
        cell_style: { inline_format: true }.merge(styles.participants_table_cell)
      )
    end
  end

  def participants_table_column_widths(columns_count)
    width = pdf.bounds.width / columns_count
    [width] * columns_count
  end

  def participants
    meeting.participants.sort_by(&:name)
  end

  def participants_groups(columns_count)
    # note participants.in_groups does not work with the alphabetically sorted requirement
    # should be left to right and then the next row
    array = Array.new(columns_count) { [] }
    chunks = participants.in_groups_of(columns_count)
    chunks.each do |chunk|
      chunk.each_with_index do |participant, participant_index|
        array[participant_index] << participant
      end
    end
    array
  end

  def participants_table_rows(columns_count)
    groups = participants_groups(columns_count)
    return [] if groups.empty?

    Array.new(groups[0].size) do |row_index|
      (0..(columns_count - 1)).map do |group_nr|
        participant = groups.dig(group_nr, row_index)
        { content: "#{participant_name(participant)}   #{participants_status(participant)}".strip }
      end
    end
  end

  def participants_status(participant)
    return "" if participant.nil?

    content = if participant.attended?
                I18n.t("description_attended")
              else
                ""
              end
    prawn_table_cell_inline_formatting_data(content.capitalize, styles.participants_status)
  end

  def participant_name(participant)
    return "" if participant.nil?

    participant.name
  end

  def participants_title
    "#{Meeting.human_attribute_name(:participants)} (#{meeting.participants.count})"
  end
end
