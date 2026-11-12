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

module Meetings::PDF::Minutes::PageHead
  def write_page_head
    write_page_title
    write_page_subheading
    write_meeting_subtitle
  end

  def write_page_title
    style = styles.page_heading
    with_vertical_margin(styles.page_heading_margins) do
      pdf.formatted_text([style.merge({ text: meeting.title })], style)
    end
  end

  def write_page_subheading
    style = styles.page_subheading
    with_vertical_margin(styles.page_subheading_margins) do
      pdf.formatted_text([style.merge({ text: I18n.t("meeting.export.minutes.title") })], style)
    end
  end

  def write_meeting_subtitle
    style = styles.page_subtitle
    with_vertical_margin(styles.page_subtitle_margins) do
      pdf.formatted_text([style.merge({ text: meeting_subtitle })], style)
    end
  end

  def meeting_subtitle_date
    format_date(meeting.start_time)
  end

  def meeting_subtitle_time
    "#{format_time(meeting.start_time, include_date: false)} – #{format_time(meeting.end_time, include_date: false)}"
  end

  def meeting_subtitle_first_line
    list = [
      "#{I18n.t('meeting.export.minutes.date')}:", meeting_subtitle_date, "|",
      "#{I18n.t('meeting.export.minutes.time')}:", meeting_subtitle_time
    ]
    if meeting.location.present?
      list += ["|", "#{I18n.t('meeting.export.minutes.location')}:", meeting.location]
    end
    list.join(" ")
  end

  def meeting_subtitle
    result = meeting_subtitle_first_line
    if minutes_author.present?
      result += "\n#{I18n.t('meeting.export.minutes.author')}: #{minutes_author}"
    end
    result
  end
end
