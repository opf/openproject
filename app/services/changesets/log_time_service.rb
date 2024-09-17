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

module Changesets
  class LogTimeService
    def initialize(user:, changeset:)
      self.user = user
      self.changeset = changeset
    end

    def call(work_package, hours)
      service_result = TimeEntries::CreateService
                       .new(user:)
                       .call(combined_parameters(work_package, hours))

      log_error(service_result)

      service_result
    end

    private

    attr_accessor :user,
                  :changeset

    def combined_parameters(work_package, hours)
      params = {
        hours:,
        work_package:,
        spent_on: changeset.commit_date,
        comments: I18n.t(:text_time_logged_by_changeset, value: changeset.text_tag, locale: Setting.default_language)
      }

      activity = log_time_activity

      params[:activity] = activity if activity.present?

      params
    end

    def log_error(service_result)
      unless service_result.success?
        errors = service_result.errors.full_messages.join(", ")
        Rails.logger.warn("TimeEntry could not be created by changeset #{changeset.id}: #{errors}")
      end
    end

    def log_time_activity
      if Setting.commit_logtime_activity_id.to_i.positive?
        TimeEntryActivity.find_by(id: Setting.commit_logtime_activity_id.to_i)
      end
    end
  end
end
