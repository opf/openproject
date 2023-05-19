#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

    attr_reader :project, :statuses, :repository, :types
    alias_method :project_data, :seed_data

    def initialize(project, project_data)
      super(project_data)
      @project = project
      @project_data = project_data
      @statuses = Status.all
      @repository = Repository.first
      @types = project.types.all.reject(&:is_milestone?)
    end

    def seed_data!
      print_status '    ↳ Creating work_packages' do
        seed_demo_work_packages
        set_work_package_relations
      end
    end

    private

    def seed_demo_work_packages
      project_data.each('work_packages') do |attributes|
        work_package = create_or_update_work_package(attributes)
        memorize_work_package(work_package, attributes)
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

      work_package = WorkPackage.create wp_attr

      create_children! work_package, attributes
      create_attachments! work_package, attributes

      description = work_package.description
      description = link_attachments description, work_package.attachments
      description = with_references description

      work_package.update(description:)

      work_package
    end

    def create_children!(work_package, attributes)
      Array(attributes['children']).each do |child_attributes|
        child = create_work_package child_attributes

        child.parent = work_package
        child.save!
        memorize_work_package(child, child_attributes)
      end
    end

    def base_work_package_attributes(attributes)
      {
        project:,
        author: user,
        assigned_to: find_principal(attributes['assigned_to']),
        subject: attributes['subject'],
        description: attributes['description'],
        status: find_status(attributes),
        type: find_type(attributes),
        priority: find_priority(attributes) || IssuePriority.default,
        parent: find_work_package(attributes['parent'])
      }
    end

    def memorize_work_package(work_package, attributes)
      project_data.store_reference(attributes['reference'], work_package)
      attributes['work_package'] = work_package
    end

    def find_work_package(reference)
      seed_data.find_reference(reference)
    end

    def find_principal(reference)
      seed_data.find_reference(reference) || user
    end

    def find_priority(attributes)
      IssuePriority.find_by(name: I18n.t(attributes['priority']))
    end

    def find_status(attributes)
      Status.find_by!(name: I18n.t(attributes['status']))
    end

    def find_type(attributes)
      Type.find_by!(name: I18n.t(attributes['type']))
    end

    def set_version!(wp_attr, attributes)
      version = seed_data.find_reference(attributes['version'])
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
      wp_attr[:position] = attributes['position'].presence&.to_i
      wp_attr[:story_points] = attributes['story_points'].presence&.to_i
    end

    def set_work_package_relations
      project_data.each('work_packages') do |attributes|
        create_relations attributes
      end
    end

    def create_relations(attributes)
      Array(attributes['relations']).each do |relation|
        root_work_package = attributes['work_package'] # memorized on creation
        to_work_package = find_work_package(relation['to'])
        create_relation(
          to: to_work_package,
          from: root_work_package,
          type: relation['type']
        )
      end

      Array(attributes['children']).each do |child_attributes|
        create_relations child_attributes
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
        days_ahead = attributes['start'] || 0
        Time.zone.today.monday + days_ahead.days
      end

      def due_date
        all_days.due_date(start_date, attributes['duration'])
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
        attributes['estimated_hours']&.to_i
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
