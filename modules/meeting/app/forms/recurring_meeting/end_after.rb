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

class RecurringMeeting::EndAfter < ApplicationForm
  form do |meeting_form|
    meeting_form.select_list(
      name: "end_after",
      required: true,
      label: I18n.t("activerecord.attributes.recurring_meeting.end_after"),
      data: {
        target_name: "end_after",
        "show-when-value-selected-target": "cause",
        action: "input->recurring-meetings--form#updateFrequencyText"
      }
    ) do |list|
      list.option(value: "never", label: I18n.t("recurring_meeting.end_after.never"))
      list.option(value: "specific_date", label: I18n.t("recurring_meeting.end_after.specific_date"))
      list.option(value: "iterations", label: I18n.t("recurring_meeting.end_after.iterations"))
    end
  end
end
