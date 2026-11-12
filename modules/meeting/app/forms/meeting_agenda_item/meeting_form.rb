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

class MeetingAgendaItem::MeetingForm < ApplicationForm
  include Redmine::I18n

  form do |agenda_item_form|
    agenda_item_form.autocompleter(
      name: :meeting_id,
      required: true,
      include_blank: false,
      label: I18n.t("label_meeting"),
      caption: I18n.t("label_meeting_selection_caption"),
      autocomplete_options: {
        component: "opce-meeting-autocompleter",
        hiddenFieldAction: "change->refresh-on-form-changes#triggerTurboStream",
        items: meeting_options,
        group_by: "group_label",
        focus_directly: true,
        defaultData: false,
        bindLabel: "name",
        bindValue: "id",
        multiple: false,
        append_to: append_to_container,
        model: meeting_options.detect { |option| option[:id] == model.meeting_id },
        inputValue: model.meeting_id,
        virtualScroll: false
      }
    )
  end

  def initialize(disabled: false, wrapper_id: nil)
    super()

    @disabled = disabled
    @wrapper_id = wrapper_id
  end

  private

  def meeting_options
    meetings = MeetingAgendaItems::CreateContract
      .assignable_meetings(User.current)
      .where("meetings.start_time + (interval '1 hour' * meetings.duration) >= ?", Time.zone.now)
      .order("meetings.start_time")
      .includes(:project)

    GroupMeetingsService.new(meetings, as_options: true).call.result
  end

  def append_to_container
    @wrapper_id.nil? ? "body" : "##{@wrapper_id}"
  end
end
