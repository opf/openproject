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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module TimeEntries
  class SetAttributesService < ::BaseServices::SetAttributes
    private

    def set_attributes(_attributes) # rubocop:disable Metrics/AbcSize
      model.attributes = params

      ##
      # Update project context if moving time entry
      if no_project_or_context_changed?
        model.project = model.entity&.project
      end

      set_default_attributes(params) if model.new_record?

      # move the timezone from the user
      model.change_by_system do
        model.time_zone = model.user.time_zone.name if model.user
      end

      # Set start time for ongoing time entries
      ensure_start_time_for_onging_entries

      # Always set the logging user as logged_by
      set_logged_by

      # Set custom_values_to_validate for customizable models
      set_custom_values_to_validate(params)
    end

    def set_default_attributes(*)
      set_default_user
      set_default_hours
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

    def set_default_hours
      model.hours = nil if model.hours&.zero?
    end

    def no_project_or_context_changed?
      !model.project ||
        (model.entity && model.entity_changed? && !model.project_id_changed?)
    end

    def ensure_start_time_for_onging_entries
      return unless model.new_record?
      return unless model.ongoing?
      return unless TimeEntry.can_track_start_and_end_time?

      Time.use_zone(model.user.time_zone) do
        model.start_time ||= Time.zone.now.strftime("%H:%M")
      end
    end
  end
end
