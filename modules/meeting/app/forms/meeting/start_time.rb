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

class Meeting::StartTime < ApplicationForm
  form do |meeting_form|
    meeting_form.text_field(
      name: :start_time_hour,
      type: "time",
      value: @initial_value,
      placeholder: Meeting.human_attribute_name(:start_time),
      label: Meeting.human_attribute_name(:start_time),
      leading_visual: { icon: :clock },
      required: true,
      caption: Time.zone.to_s[/\((.*?)\)/m, 1]
    )
  end

  def initialize(initial_value: DateTime.now.strftime("%H:%M"))
    @initial_value = initial_value
  end
end
