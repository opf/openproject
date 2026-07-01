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

module DevelopmentData
  module ResourceManagement
    # Seeds the `dev-resource-management` project with work packages, a planner
    # and allocations, including a deliberate overbooking case. Run after
    # DevelopmentData::UsersSeeder so the dev users it allocates already exist.
    class ProjectSeeder < ::Seeder
      PROJECT_IDENTIFIER = "dev-resource-management"
      DEV_MEMBER_LOGINS = %w[member work_packager project_admin].freeze

      # [subject, start offset, finish offset] in calendar days from the anchor
      # Monday. "Plan" and "Model" overlap in the first week on purpose.
      WORK_PACKAGES = [
        ["Project kickoff and planning", 0, 4],
        ["Design timeline data model",   0, 11],
        ["Build allocation API",         7, 18],
        ["Implement timeline frontend",  14, 25],
        ["QA and overallocation checks", 21, 32],
        ["Release preparation",          28, 32]
      ].freeze

      # [work package subject, assignee login, share of capacity]. The first two
      # rows put `member` on the two overlapping work packages at full capacity,
      # which makes them overbooked.
      ALLOCATIONS = [
        ["Project kickoff and planning", "member",        :full],
        ["Design timeline data model",   "member",        :full],
        ["Build allocation API",         "work_packager", :full],
        ["Implement timeline frontend",  "project_admin", :full],
        ["QA and overallocation checks", "work_packager", :half],
        ["Release preparation",          "admin",         :full]
      ].freeze

      # APIV3 filter JSON for the automatically filtered timeline: open work packages.
      OPEN_STATUS_FILTER = %([{"status_id":{"operator":"o","values":[]}}])

      # Hand-picked timeline contents, in a deliberately non-chronological order
      # to showcase the manual reordering.
      HANDPICKED_TIMELINE = [
        "Implement timeline frontend",
        "Design timeline data model",
        "Build allocation API"
      ].freeze

      def seed_data!
        print_status "    ↳ Creating the #{PROJECT_IDENTIFIER} project with resource allocations"

        create_project
        add_members
        seed_working_hours
        work_packages = seed_work_packages
        planner = seed_planner(work_packages)
        seed_timeline_views(planner, work_packages)
        seed_allocations(work_packages)
      end

      def applicable?
        OpenProject::FeatureDecisions.resource_management_active? &&
          Project.where(identifier: PROJECT_IDENTIFIER).none?
      end

      def not_applicable_message
        if OpenProject::FeatureDecisions.resource_management_active?
          "Not seeding #{PROJECT_IDENTIFIER}: it already exists."
        else
          "Not seeding #{PROJECT_IDENTIFIER}: resource_management feature is not active."
        end
      end

      private

      def project
        return @project if defined?(@project)

        @project = Project.find_by(identifier: PROJECT_IDENTIFIER)
      end

      def create_project
        @project = Project.create!(
          name: "[dev] Resource management",
          identifier: PROJECT_IDENTIFIER,
          enabled_module_names: %w[work_package_tracking resource_management gantt],
          types: Type.all,
          workspace_type: "project",
          public: false
        )
      end

      # A role with the resource_management permissions, so these users can be
      # allocated and can use the planner when logged in as them.
      def add_members
        role = resource_role
        return unless role

        allocatable_users.each do |user|
          Member.create!(project:, principal: user, roles: [role])
        end
      end

      # Mon-Fri 8h capacity so the overbooking computation has working hours to
      # compare allocations against (users without working hours are skipped).
      def seed_working_hours
        allocatable_users.each do |user|
          next if UserWorkingHours.exists?(user_id: user.id)

          UserWorkingHours.create!(
            user:, valid_from: Date.new(2026, 1, 1),
            monday: 480, tuesday: 480, wednesday: 480, thursday: 480, friday: 480,
            saturday: 0, sunday: 0, availability_factor: 100
          )
        end
      end

      def seed_work_packages
        WORK_PACKAGES.index_with do |(subject, start_offset, finish_offset)|
          WorkPackage.create!(
            project:, type: default_type, status: default_status, priority: default_priority,
            author: admin_user, subject:,
            start_date: anchor_monday + start_offset, due_date: anchor_monday + finish_offset
          )
        end.transform_keys(&:first)
      end

      def seed_planner(work_packages) # rubocop:disable Metrics/AbcSize
        planner = ResourcePlanner.create!(
          name: "Team allocations",
          project:, principal: planner_owner, public: true,
          start_date: work_packages.values.map(&:start_date).min,
          end_date: work_packages.values.map(&:due_date).max
        )

        list = ResourceWorkPackageList.new(name: "Work packages", parent: planner, project:, principal: planner_owner)
        query = list.build_default_query
        query.name = list.name
        list.query = query
        list.save!

        planner.update!(default_view_id: list.id)
        planner
      end

      def seed_timeline_views(planner, work_packages)
        seed_filtered_timeline(planner)
        seed_handpicked_timeline(planner, work_packages)
      end

      # Configure the query the same way the UI does, so seeded views behave
      # exactly like user-created ones.
      def seed_filtered_timeline(planner)
        view = ResourceWorkPackageTimeline.new(
          name: "Work packages timeline", parent: planner, project:, principal: planner_owner
        )
        view.query = view.build_default_query
        view.apply_query_configuration(filters_json: OPEN_STATUS_FILTER, filter_mode: "automatic")
        view.save!
      end

      def seed_handpicked_timeline(planner, work_packages)
        view = ResourceWorkPackageTimeline.new(
          name: "Hand-picked timeline", parent: planner, project:, principal: planner_owner
        )
        view.query = view.build_default_query
        view.apply_query_configuration(filters_json: nil, filter_mode: "manual")
        view.save!

        HANDPICKED_TIMELINE.each_with_index do |subject, index|
          work_package = work_packages[subject]
          view.query.ordered_work_packages.create!(work_package:, position: index + 1) if work_package
        end
      end

      def seed_allocations(work_packages)
        ALLOCATIONS.each do |subject, login, share|
          work_package = work_packages[subject]
          user = allocatable_users_by_login[login]
          next unless work_package && user

          create_allocation(work_package, user, share)
        end
      end

      def create_allocation(work_package, user, share)
        minutes = working_days(work_package.start_date, work_package.due_date) * 480
        minutes /= 2 if share == :half

        ResourceAllocation.create!(
          entity: work_package,
          principal: user,
          requested_by: admin_user,
          reviewed_by: admin_user,
          state: "allocated",
          principal_explicit: true,
          start_date: work_package.start_date,
          end_date: work_package.due_date,
          allocated_time: [minutes, 480].max
        )
      end

      def anchor_monday
        @anchor_monday ||= Date.new(2026, 6, 1).beginning_of_week
      end

      def working_days(range_start, range_end)
        (range_start..range_end).count { |date| !date.saturday? && !date.sunday? }
      end

      def dev_users
        @dev_users ||= User.where(login: DEV_MEMBER_LOGINS).to_a
      end

      def allocatable_users
        @allocatable_users ||= ([admin_user] + dev_users).compact
      end

      def allocatable_users_by_login
        @allocatable_users_by_login ||= allocatable_users.index_by(&:login)
      end

      def planner_owner
        allocatable_users_by_login["project_admin"] || admin_user
      end

      def resource_role
        ProjectRole.givable.detect { |role| role.permissions.include?(:allocate_user_resources) }
      end

      def default_type
        @default_type ||= project.types.find_by(name: "Task") || project.types.first
      end

      def default_status
        @default_status ||= Status.default || Status.first
      end

      def default_priority
        @default_priority ||= IssuePriority.default || IssuePriority.active.first || IssuePriority.first
      end
    end
  end
end
