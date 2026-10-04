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

module Meetings::PDF::Default::Attachments
  def write_attachments_list
    return if meeting.attachments.empty?

    columns_count = [meeting.attachments.size, 3].min
    rows = meeting_attachments_table_rows(columns_count)
    return if rows.empty?

    write_hr
    write_heading(attachments_list_title)
    write_attachments_list_table(rows, columns_count)
  end

  def write_attachments_list_table(rows, columns_count)
    with_vertical_margin(styles.attachments_margins) do
      pdf.table(
        rows,
        column_widths: attachments_list_table_column_widths(columns_count),
        cell_style: styles.attachments_table_cell
      )
    end
  end

  def attachments_list_table_column_widths(columns_count)
    width = pdf.bounds.width / columns_count
    [width] * columns_count
  end

  def meeting_attachments_table_rows(columns_count)
    groups = meeting.attachments.in_groups(columns_count)
    return [] if groups.empty?

    Array.new(groups[0].size) do |row_index|
      (0..(columns_count - 1)).map do |group_nr|
        { content: attachment_name(groups.dig(group_nr, row_index)), inline_format: true }
      end
    end
  end

  def attachment_name(attachment)
    return "" if attachment.nil?

    make_link_href(attachment_link_href(attachment), "<u>#{attachment.filename}</u>")
  end

  def attachment_link_href(attachment)
    "#{Setting.protocol}://#{Setting.host_name}#{
      API::V3::Utilities::PathHelper::ApiV3Path.attachment_content(attachment.id)
    }"
  end

  def attachments_list_title
    I18n.t(:label_attachment_plural)
  end
end
