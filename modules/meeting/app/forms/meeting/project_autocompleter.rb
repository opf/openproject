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

class Meeting::ProjectAutocompleter < ApplicationForm
  form do |f|
    f.project_autocompleter(
      name: "project_id",
      id: "project_id",
      label: Project.model_name.human,
      required: true,
      caption:,
      autocomplete_options: {
        with_search_icon: true,
        openDirectly: false,
        focusDirectly: false,
        dropdownPosition: "bottom",
        appendTo: "#new-meeting-dialog",
        filters: [{ name: "user_action", operator: "=", values: ["meetings/create"] }],
        hiddenFieldAction: "change->refresh-on-form-changes#triggerTurboStream",
        data: {
          "test-selector": "project_id"
        }
      }
    )
  end

  def initialize(meeting:)
    super()

    @meeting = meeting
  end

  def caption
    return if @meeting.is_a?(RecurringMeeting)

    @meeting.onetime_template? ? I18n.t("caption_template_project_select") : nil
  end
end
