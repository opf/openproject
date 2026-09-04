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

module ResourceManagement
  module DevelopmentData
    # Adds a resource planner to a demo project: one of each of the four planner
    # views and a handful of allocations (explicit and filter-based, including a
    # deliberate overbooking). Runs only for projects that carry `resource_planner`
    # seed data, so it augments the existing demo project rather than seeding a
    # dedicated one.
    #
    # Driven per project by ResourcePlannersSeeder, which runs after the demo data.
    class ResourcePlannerSeeder < ::Seeder
      # APIV3 filter JSON for the automatically filtered timeline: open work packages.
      OPEN_STATUS_FILTER = %([{"status_id":{"operator":"o","values":[]}}])
      FULL_DAY_MINUTES = 480

      # Work packages (by seed reference) the allocations attach to.
      WORK_PACKAGE_REFERENCES = %i[
        set_date_and_location_of_conference
        invite_attendees_to_conference
        setup_conference_website
        follow_up_tasks
        upload_presentations_to_website
      ].freeze

      attr_reader :project
      alias_method :project_data, :seed_data

      def initialize(project, project_data)
        super(project_data)
        @project = project
      end

      def seed_data!
        print_status "    ↳ Creating a resource planner with views and allocations" do
          enable_module
          planner = seed_planner
          seed_views(planner)
          seed_allocations
        end
      end

      def applicable?
        planner_config.present?
      end

      def not_applicable_message
        "Skipping resource planner for #{project.identifier}: " \
          "the project has no resource_planner seed data."
      end

      private

      def planner_config
        @planner_config ||= project_data.lookup("resource_planner")
      end

      def owner
        admin_user
      end

      def enable_module
        return if project.enabled_module_names.include?("resource_management")

        project.enabled_modules.create!(name: "resource_management")
      end

      def seed_planner
        ResourcePlanner.create!(
          name: planner_config.lookup("name"),
          project:, principal: owner, public: true,
          **planner_dates
        )
      end

      # The timeframe is a range: it is either left empty or both of its ends are
      # given, so a set of work packages dated only on one side yields no range.
      def planner_dates
        start_date = work_packages.values.compact.filter_map(&:start_date).min
        end_date = work_packages.values.compact.filter_map(&:due_date).max
        return {} if start_date.nil? || end_date.nil?

        { start_date:, end_date: }
      end

      def seed_views(planner)
        list = seed_work_package_list(planner)
        seed_work_package_timeline(planner)
        seed_user_card(planner)
        seed_user_timeline(planner)

        planner.update!(default_view_id: list.id)
      end

      def seed_work_package_list(planner)
        view = ResourceWorkPackageList.new(view_attributes(planner, "work_package_list"))
        query = view.build_default_query
        query.name = view.name
        view.query = query
        view.save!
        view
      end

      def seed_work_package_timeline(planner)
        view = ResourceWorkPackageTimeline.new(view_attributes(planner, "work_package_timeline"))
        view.query = view.build_default_query
        view.apply_query_configuration(filters_json: OPEN_STATUS_FILTER, filter_mode: "automatic")
        view.save!
      end

      def seed_user_card(planner)
        view = ResourceUserCard.new(view_attributes(planner, "user_card"))
        view.query = view.build_default_query
        view.apply_query_configuration(filters_json: nil, filter_mode: "automatic")
        view.save!
      end

      def seed_user_timeline(planner)
        view = ResourceUserTimeline.new(view_attributes(planner, "user_timeline"))
        view.query = view.build_default_query
        view.apply_query_configuration(filters_json: nil, filter_mode: "automatic")
        view.save!
      end

      def view_attributes(planner, key)
        { name: planner_config.lookup("#{key}.name"), parent: planner, project:, principal: owner }
      end

      def seed_allocations
        # Wanda is booked full-time on the website for its whole span, which
        # already uses up her capacity. The additional (realistic, single-day)
        # allocation for inviting attendees overlaps it and overbooks her, which
        # the user timeline then surfaces.
        create_explicit_allocation(:setup_conference_website, :user__wanda_web, :full)
        create_explicit_allocation(:invite_attendees_to_conference, :user__wanda_web, :full)
        create_explicit_allocation(:set_date_and_location_of_conference, :user__olga_ops, :full)
        create_explicit_allocation(:follow_up_tasks, :user__adam_admin, :half)
        seed_generic_allocation
      end

      # A filter-based allocation: no concrete user, just a demand for anyone
      # matching the "Software Developer" job title. Skipped when the demo user
      # custom fields it filters on are absent.
      def seed_generic_allocation
        work_package = work_packages[:upload_presentations_to_website]
        filters = developer_filter
        return unless work_package && filters

        ResourceAllocation.create!(
          base_allocation_attributes(work_package, :full).merge(
            principal: nil,
            principal_explicit: false,
            filter_name: planner_config.lookup("generic_allocation.filter_name"),
            user_filter: filters
          )
        )
      end

      def create_explicit_allocation(work_package_reference, user_reference, share)
        work_package = work_packages[work_package_reference]
        principal = find_user(user_reference)
        return unless work_package && principal

        ResourceAllocation.create!(
          base_allocation_attributes(work_package, share).merge(principal:, principal_explicit: true)
        )
      end

      def base_allocation_attributes(work_package, share)
        {
          entity: work_package,
          requested_by: admin_user,
          reviewed_by: admin_user,
          state: "allocated",
          start_date: work_package.start_date,
          end_date: work_package.due_date,
          allocated_time: allocated_minutes(work_package.start_date, work_package.due_date, share)
        }
      end

      def developer_filter
        custom_field = UserCustomField.for_semantic_key(:job_title)
        option = custom_field&.custom_options&.find_by(value: "Software Developer")
        return unless option

        query = UserQuery.new
        query.where(custom_field.column_name, "=", [option.id.to_s])
        query.filters
      end

      def allocated_minutes(start_date, end_date, share)
        minutes = working_days(start_date, end_date) * FULL_DAY_MINUTES
        minutes /= 2 if share == :half
        [minutes, FULL_DAY_MINUTES].max
      end

      def working_days(range_start, range_end)
        (range_start..range_end).count { |date| !date.saturday? && !date.sunday? }
      end

      def work_packages
        @work_packages ||= WORK_PACKAGE_REFERENCES.index_with { |reference| seed_data.find_reference(reference, default: nil) }
      end

      def find_user(reference)
        seed_data.find_reference(reference, default: nil)
      end
    end
  end
end
