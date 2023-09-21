#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

class MeetingAgendaItem::MeetingForm < ApplicationForm
  include Redmine::I18n

  form do |agenda_item_form|
    agenda_item_form.select_list(
      name: :meeting_id,
      required: true,
      include_blank: false,
      label: Meeting.model_name.human,
      caption: I18n.t("label_meeting_selection_caption")
    ) do |meeting_select_list|
      # TODO: Clarify scope
      StructuredMeeting.open.where('meetings.start_time >= ?', Time.zone.now).each do |meeting|
        meeting_select_list.option(
          label: "#{meeting.title} #{format_date(meeting.start_time)} #{format_time(meeting.start_time, false)}",
          value: meeting.id
        )
      end
    end
  end

  def initialize(disabled: false)
    super()
    @disabled = disabled
  end
end
