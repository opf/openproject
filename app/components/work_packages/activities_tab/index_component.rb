# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2023 the OpenProject GmbH
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
# ++

module WorkPackages
  module ActivitiesTab
    class IndexComponent < ApplicationComponent
      include ApplicationHelper
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      def initialize(work_package:, filter: :all)
        super

        @work_package = work_package
        @filter = filter
      end

      private

      attr_reader :work_package, :filter

      def wrapper_data_attributes
        {
          test_selector: "op-wp-activity-tab",
          controller: "work-packages--activities-tab--index",
          "application-target": "dynamic",
          "work-packages--activities-tab--index-update-streams-url-value": update_streams_work_package_activities_url(
            work_package
          ),
          "work-packages--activities-tab--index-sorting-value": journal_sorting,
          "work-packages--activities-tab--index-filter-value": filter,
          "work-packages--activities-tab--index-user-id-value": User.current.id,
          "work-packages--activities-tab--index-work-package-id-value": work_package.id,
          "work-packages--activities-tab--index-polling-interval-in-ms-value": polling_interval,
          "work-packages--activities-tab--index-notification-center-path-name-value": notifications_path
        }
      end

      def journal_sorting
        User.current.preference&.comments_sorting || "desc"
      end

      def polling_interval
        # Polling interval should only be adjustable in test environment
        if Rails.env.test?
          ENV["WORK_PACKAGES_ACTIVITIES_TAB_POLLING_INTERVAL_IN_MS"].presence || 10000
        else
          10000
        end
      end

      def adding_comment_allowed?
        User.current.allowed_in_project?(:add_work_package_notes, @work_package.project)
      end
    end
  end
end
