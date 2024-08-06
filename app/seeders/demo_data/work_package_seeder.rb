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
module DemoData
  class WorkPackageSeeder < Seeder
    include CreateAttachments
    include References

    self.needs = [
      BasicData::StatusSeeder,
      BasicData::TypeSeeder,
      BasicData::PrioritySeeder,
      AdminUserSeeder
    ]

    attr_reader :project, :statuses, :repository, :types
    alias_method :project_data, :seed_data

    def initialize(project, project_data)
      super(project_data)
      @project = project
      @project_data = project_data
      @statuses = Status.all
      @repository = Repository.first
      @types = project.types.all.reject(&:is_milestone?)
      @relations_to_create = []
    end

    def seed_data!
      print_status "    ↳ Creating work_packages" do
        seed_demo_work_packages
        set_work_package_relations
      end
    end

    private

    RelationData = Data.define(:from, :to_reference, :type)

    attr_reader :relations_to_create

    def seed_demo_work_packages
      project_data.each("work_packages") do |attributes|
        create_or_update_work_package(attributes)
      end
    end

    # Decides what to do with work package seed data.
    # The default here is to create the work package.
    # Modules may patch this method.
    def create_or_update_work_package(attributes)
      create_work_package(attributes)
    end

    def create_work_package(attributes)
      wp_attr = base_work_package_attributes attributes

      set_version! wp_attr, attributes
      set_time_tracking_attributes! wp_attr, attributes
      set_backlogs_attributes! wp_attr, attributes

      work_package = WorkPackage.create! wp_attr

      create_children! work_package, attributes
      create_attachments! work_package, attributes
      update_description! work_package
      add_relations_to_create work_package, attributes
      memorize_work_package work_package, attributes

      work_package
    end

    def base_work_package_attributes(attributes)
      {
        project:,
        author: admin_user,
        assigned_to: find_principal(attributes["assigned_to"]),
        subject: attributes["subject"],
        description: attributes["description"],
        status: find_status(attributes),
        type: find_type(attributes),
        priority: IssuePriority.default,
        parent: find_work_package(attributes["parent"])
      }
    end

    def create_children!(work_package, attributes)
      Array(attributes["children"]).each do |child_attributes|
        child = create_work_package child_attributes

        child.parent = work_package
        child.save!
      end
    end

    def update_description!(work_package)
      description = work_package.description
      description = link_attachments description, work_package.attachments
      description = with_references description

      work_package.update(description:)
    end

    def add_relations_to_create(work_package, attributes)
      Array(attributes["relations"]).each do |relation|
        relation_data = RelationData.new(from: work_package, to_reference: relation["to"], type: relation["type"])
        relations_to_create.push(relation_data)
      end
    end

    def memorize_work_package(work_package, attributes)
      project_data.store_reference(attributes["reference"], work_package)
    end

    def find_work_package(reference)
      seed_data.find_reference(reference)
    end

    def find_principal(reference)
      seed_data.find_reference(reference) || admin_user
    end

    def find_status(attributes)
      seed_data.find_reference(attributes["status"].to_sym)
    end

    def find_type(attributes)
      seed_data.find_reference(attributes["type"].to_sym)
    end

    def set_version!(wp_attr, attributes)
      version = seed_data.find_reference(attributes["version"])
      if version
        wp_attr[:version] = version
      end
    end

    def set_time_tracking_attributes!(wp_attr, attributes)
      wp_attr.merge!(time_tracking_attributes(attributes))
    end

    def time_tracking_attributes(attributes)
      TimeTrackingAttributes.for(attributes)
    end

    def set_backlogs_attributes!(wp_attr, attributes)
      wp_attr[:position] = attributes["position"].presence&.to_i
      wp_attr[:story_points] = attributes["story_points"].presence&.to_i
    end

    def set_work_package_relations
      while relations_to_create.any?
        relation_data = relations_to_create.pop
        from_work_package = relation_data.from
        to_work_package = find_work_package(relation_data.to_reference)
        create_relation(
          to: to_work_package,
          from: from_work_package,
          type: relation_data.type
        )
      end
    end

    def create_relation(to:, from:, type:)
      Relation.create!(from:, to:, relation_type: type)
    end

    class TimeTrackingAttributes
      def self.for(attributes)
        new(attributes).work_package_attributes
      end

      def work_package_attributes
        {
          start_date:,
          due_date:,
          duration:,
          ignore_non_working_days:,
          estimated_hours:
        }
      end

      private

      attr_reader :attributes

      def initialize(attributes)
        @attributes = attributes
      end

      def start_date
        days_ahead = attributes["start"] || 0
        Time.zone.today.monday + days_ahead.days
      end

      def due_date
        all_days.due_date(start_date, attributes["duration"])
      end

      def duration
        days.duration(start_date, due_date)
      end

      def ignore_non_working_days
        [start_date, due_date]
          .compact
          .any? { |date| working_days.non_working?(date) }
      end

      def estimated_hours
        attributes["estimated_hours"]&.to_i
      end

      def all_days
        @all_days ||= WorkPackages::Shared::AllDays.new
      end

      def working_days
        @working_days ||= WorkPackages::Shared::WorkingDays.new
      end

      def days
        ignore_non_working_days ? all_days : working_days
      end
    end
  end
end
