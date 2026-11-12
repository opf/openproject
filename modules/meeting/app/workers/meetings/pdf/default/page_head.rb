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

module Meetings::PDF::Default::PageHead
  def write_page_head
    with_vertical_margin(styles.page_heading_margins) do
      write_page_title
    end
    with_vertical_margin(styles.page_subtitle_margins) do
      write_meeting_subtitle
    end
    write_hr
  end

  def write_page_title
    style = styles.page_heading
    pdf.formatted_text([style.merge(
      { text: meeting.title, link: url_helpers.meeting_url(meeting) }
    )], style)
  end

  def write_meeting_subtitle
    style = styles.page_subtitle
    pdf.formatted_text([style.merge({ text: meeting_subtitle })], style)
  end

  def meeting_subtitle
    [
      "#{meeting_mode} (#{I18n.t("label_meeting_state_#{meeting.state}")}),",
      "#{format_date(meeting.start_time)},",
      format_time(meeting.start_time, include_date: false),
      "–",
      format_time(meeting.end_time, include_date: false)
    ].join(" ")
  end
end
