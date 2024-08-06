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

module TimeEntries
  class UpdateContract < BaseContract
    include UnchangedProject

    validate :validate_user_allowed_to_update

    def validate_user_allowed_to_update
      unless user_allowed_to_update?
        errors.add :base, :error_unauthorized
      end
    end

    ##
    # Users may update time entries IF
    # they have the :edit_time_entries or
    # user == editing user and :edit_own_time_entries
    def user_allowed_to_update?
      if model.ongoing || model.ongoing_was
        with_unchanged_project_id do
          user_allowed_to_modify_ongoing?(model)
        end && user_allowed_to_modify_ongoing?(model)
      else
        with_unchanged_project_id do
          user_allowed_to_update_in?(model)
        end && user_allowed_to_update_in?(model)
      end
    end

    private

    def user_allowed_to_update_in?(time_entry)
      user.allowed_in_project?(:edit_time_entries, time_entry.project) ||
        (model.user == user && user.allowed_in_work_package?(:edit_own_time_entries, time_entry.work_package))
    end

    def user_allowed_to_modify_ongoing?(time_entry)
      model.user == user && (user.allowed_in_project?(:log_time,
                                                      time_entry.project) || user.allowed_in_work_package?(:log_own_time,
                                                                                                           time_entry.work_package))
    end
  end
end
