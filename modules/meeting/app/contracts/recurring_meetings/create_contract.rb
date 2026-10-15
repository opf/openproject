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

module RecurringMeetings
  class CreateContract < BaseContract
    attribute :uid
    attribute :current_schedule_start

    validate :user_allowed_to_add
    validate :project_is_present
    validate :start_time_constraints

    private

    def project_is_present
      if model.project.nil?
        errors.add :project_id, :blank
      end
    end

    def user_allowed_to_add
      return if model.project.nil?

      unless user.allowed_in_project?(:create_meetings, model.project)
        errors.add :base, :error_unauthorized
      end
    end

    def start_time_constraints
      return if model.start_time.nil?
      return if model.start_time >= Time.zone.now.change(sec: 0)

      if model.start_time.today?
        errors.add :start_time_hour, :after_today
      else
        errors.add :start_date, :after_today
      end
    end
  end
end
