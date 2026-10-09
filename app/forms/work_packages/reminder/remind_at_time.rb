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

class WorkPackages::Reminder::RemindAtTime < ApplicationForm
  include Redmine::I18n

  form do |reminder_form|
    reminder_form.text_field(
      name: :remind_at_time,
      type: "time",
      value: @initial_value,
      placeholder: I18n.t(:label_time),
      label: I18n.t(:label_time),
      leading_visual: { icon: :clock },
      required: true,
      autofocus: false,
      caption: formatted_time_zone_offset
    )
  end

  def initialize(initial_value: DateTime.now.strftime("%H:%M"))
    super()

    @initial_value = initial_value
  end
end
