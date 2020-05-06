#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
module DemoData
  class WorkPackageSeeder < Seeder
    attr_accessor :project, :user, :statuses, :repository,
                  :types, :key

    include ::DemoData::References

    def initialize(project, key)
      self.project = project
      self.key = key
      self.user = User.admin.first
      self.statuses = Status.all
      self.repository = Repository.first
      self.types = project.types.all.reject(&:is_milestone?)
    end

    def seed_data!
      print '    ↳ Creating work_packages'

      seed_demo_work_packages
      set_workpackage_relations

      puts
    end

    private

    def seed_demo_work_packages
      work_packages_data = project_data_for(key, 'work_packages')

      work_packages_data.each do |attributes|
        print '.'
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
      set_accountable! wp_attr, attributes
      set_time_tracking_attributes! wp_attr, attributes
      set_backlogs_attributes! wp_attr, attributes

      work_package = WorkPackage.create wp_attr

      create_children! work_package, attributes
      create_attachments! work_package, attributes

      description = work_package.description
      description = link_attachments description, work_package.attachments
      description = link_children description, work_package
      description = with_references description, project

      work_package.update description: description

      work_package
    end

    def create_children!(work_package, attributes)
      Array(attributes[:children]).each do |child_attributes|
        print '.'
        child = create_work_package child_attributes

        child.parent = work_package
        child.save!
      end
    end

    def base_work_package_attributes(attributes)
      {
        project:       project,
        author:        user,
        assigned_to:   find_principal(attributes[:assignee]),
        subject:       attributes[:subject],
        description:   attributes[:description],
        status:        find_status(attributes),
        type:          find_type(attributes),
        priority:      find_priority(attributes) || IssuePriority.default,
        parent:        WorkPackage.find_by(subject: attributes[:parent])
      }
    end

    def find_principal(name)
      if name
        group_assignee = Group.find_by(lastname: name)
        return group_assignee unless group_assignee.nil?
      end

      user
    end

    def find_priority(attributes)
      IssuePriority.find_by(name: translate_with_base_url(attributes[:priority]))
    end

    def find_status(attributes)
      Status.find_by!(name: translate_with_base_url(attributes[:status]))
    end

    def find_type(attributes)
      Type.find_by!(name: translate_with_base_url(attributes[:type]))
    end

    def set_version!(wp_attr, attributes)
      if attributes[:version]
        wp_attr[:version] = Version.find_by!(name: attributes[:version])
      end
    end

    def set_accountable!(wp_attr, attributes)
      if attributes[:accountable]
        wp_attr[:responsible] = find_principal(attributes[:accountable])
      end
    end

    def set_time_tracking_attributes!(wp_attr, attributes)
      start_date = attributes[:start] && calculate_start_date(attributes[:start])

      wp_attr[:start_date] = start_date
      wp_attr[:due_date] = calculate_due_date(start_date, attributes[:duration]) if start_date && attributes[:duration]
      wp_attr[:done_ratio] = attributes[:done_ratio].to_i if attributes[:done_ratio]
      wp_attr[:estimated_hours] = attributes[:estimated_hours].to_i if attributes[:estimated_hours]
    end

    def set_backlogs_attributes!(wp_attr, attributes)
      if defined? OpenProject::Backlogs
        wp_attr[:position] = attributes[:position].to_i if attributes[:position].present?
        wp_attr[:story_points] = attributes[:story_points].to_i if attributes[:story_points].present?
      end
    end

    def create_attachments!(work_package, attributes)
      Array(attributes[:attachments]).each do |file_name|
        attachment = work_package.attachments.build
        attachment.author = work_package.author
        attachment.file = File.new("config/locales/media/en/#{file_name}")

        attachment.save!
      end
    end

    def set_workpackage_relations
      work_packages_data = project_data_for(key, 'work_packages')

      work_packages_data.each do |attributes|
        create_relations attributes
      end
    end

    def create_relations(attributes)
      Array(attributes[:relations]).each do |relation|
        root_work_package = WorkPackage.find_by!(subject: attributes[:subject])
        to_work_package =  WorkPackage.find_by(subject: relation[:to], project: root_work_package.project)
        to_work_package =  WorkPackage.find_by!(subject: relation[:to]) unless to_work_package.nil?
        create_relation(
          to: to_work_package,
          from: root_work_package,
          type: relation[:type]
        )
      end

      Array(attributes[:children]).each do |child_attributes|
        create_relations child_attributes
      end
    end

    def create_relation(to:, from:, type:)
      from.new_relation.tap do |relation|
        relation.to = to
        relation.relation_type = type
        relation.save!
      end
    end

    def calculate_start_date(days_ahead)
      monday = Date.today.monday
      days_ahead > 0 ? monday + days_ahead : monday
    end

    def calculate_due_date(date, duration)
      duration && duration > 1 ? date + duration : date
    end
  end
end
