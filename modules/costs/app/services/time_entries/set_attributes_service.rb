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
  class SetAttributesService < ::BaseServices::SetAttributes
    private

    def set_attributes(_attributes)
      model.attributes = params

      ##
      # Update project context if moving time entry
      if no_project_or_context_changed?
        model.project = model.work_package&.project
      end

      set_default_attributes(params) if model.new_record?

      # Always set the logging user as logged_by
      set_logged_by
    end

    def set_default_attributes(*)
      set_default_user
      set_default_hours
      set_default_activity if model.activity.nil?
    end

    def set_logged_by
      model.change_by_system do
        model.logged_by = user
      end
    end

    def set_default_user
      model.change_by_system do
        model.user ||= user
      end
    end

    def set_default_activity
      return unless TimeEntryActivity.default

      if model.project
        assign_default_project_activity
      else
        assign_default_activity
      end
    end

    def assign_default_project_activity
      if TimeEntryActivity.active_in_project(model.project).exists?(id: TimeEntryActivity.default.id)
        assign_default_activity
      end
    end

    def assign_default_activity
      model.change_by_system do
        model.activity = TimeEntryActivity.default
      end
    end

    def set_default_hours
      model.hours = nil if model.hours&.zero?
    end

    def no_project_or_context_changed?
      !model.project ||
        (model.work_package && model.work_package_id_changed? && !model.project_id_changed?)
    end
  end
end
