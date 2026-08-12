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

module ResourcePlannerViews
  module UserTimeline
    class ResourceCellComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      include AvatarHelper

      def initialize(user:, overbooked: false, schedule_missing: false, job_title_field: nil,
                     project: nil, resource_planner: nil, view: nil)
        super
        @user = user
        @overbooked = overbooked
        @schedule_missing = schedule_missing
        @job_title_field = job_title_field
        @project = project
        @resource_planner = resource_planner
        @view = view
      end

      private

      attr_reader :user

      def overbooked? = @overbooked

      def schedule_missing? = @schedule_missing

      def overbooked_label
        t("resource_management.user_timeline.overbooked")
      end

      def no_work_schedule_message
        t("resource_management.user_timeline.no_work_schedule")
      end

      def no_work_schedule_tooltip_id
        "user-timeline-no-schedule-#{user.id}"
      end

      # Built as HTML so only the department is bold.
      def details
        segments = []
        segments << tag.b(department_name) if department_name.present?
        segments << job_title if job_title.present?
        return if segments.empty?

        safe_join(segments, " - ")
      end

      # `departments` is preloaded by the controller, so `.first` hits no query.
      def department_name
        user.departments.first&.name
      end

      # Reads the values off the preloaded `custom_values` rather than going
      # through the per-record custom-field-values machinery (avoids N+1).
      # The job_title field may be multi-value, so join all matching values.
      def job_title
        return if @job_title_field.nil?

        user.custom_values
            .select { |custom_value| custom_value.custom_field_id == @job_title_field.id }
            .filter_map { |custom_value| custom_value.formatted_value.presence }
            .join(", ")
            .presence
      end
    end
  end
end
