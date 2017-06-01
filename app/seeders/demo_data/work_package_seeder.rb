#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
module DemoData
  class WorkPackageSeeder < Seeder
    attr_accessor :project, :user, :statuses, :repository,
                  :time_entry_activities, :types

    def initialize(project)
      self.project = project
      self.user = User.admin.first
      self.statuses = Status.all
      self.repository = Repository.first
      self.time_entry_activities = TimeEntryActivity.all
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
      work_packages_data = I18n.t('seeders.demo_data.work_packages')

      work_packages_data.each do |attributes|
        start_date = calculate_start_date(attributes[:start])
        version    = Version.find_by(name: attributes[:version])

        print '.'
        work_package = WorkPackage.create!(
          project:       project,
          author:        user,
          assigned_to:   user,
          subject:       attributes[:subject],
          status:        Status.find_by!(name: I18n.t(attributes[:status_name])),
          type:          Type.find_by!(name: I18n.t(attributes[:type_name])),
          start_date:    start_date,
          due_date:      calculate_due_date(start_date, attributes[:duration]),
          fixed_version: version
        )

        attributes[:children].each do |child_attributes|
          start_date = calculate_start_date(child_attributes[:start])
          version    = Version.find_by(name: child_attributes[:version])

          print '.'
          child = WorkPackage.new(
            project:       project,
            author:        user,
            assigned_to:   user,
            subject:       child_attributes[:subject],
            status:        Status.find_by!(name: I18n.t(child_attributes[:status_name])),
            type:          Type.find_by!(name: I18n.t(child_attributes[:type_name])),
            start_date:    start_date,
            due_date:      calculate_due_date(start_date, child_attributes[:duration]),
            fixed_version: version
          )

          child.parent = work_package
          child.save!
        end
      end
    end

    def set_workpackage_relations
      work_packages_data = I18n.t('seeders.demo_data.work_packages')

      work_packages_data.each do |attributes|
        attributes[:relations].each do |relation|
          create_relation(
            to:   WorkPackage.find_by!(subject: relation[:to]),
            from: WorkPackage.find_by!(subject: attributes[:subject]),
            type: relation[:type]
          )
        end

        attributes[:children].each do |child_attributes|
          child_attributes[:relations].each do |relation|
            create_relation(
              to:   WorkPackage.find_by!(subject: relation[:to]),
              from: WorkPackage.find_by!(subject: child_attributes[:subject]),
              type: relation[:type]
            )
          end
        end
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
      duration > 1 ? date + duration : date
    end
  end
end
