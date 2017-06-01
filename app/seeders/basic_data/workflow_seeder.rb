#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
#++
module BasicData
  class WorkflowSeeder < Seeder
    def seed_data!
      colors = PlanningElementTypeColor.all
      colors = colors.map { |c| { c.name =>  c.id } }.reduce({}, :merge)

      if WorkPackage.where(type_id: nil).any? || Journal::WorkPackageJournal.where(type_id: nil).any?
        # Fixes work packages that do not have a type yet. They receive the standard type.
        #
        # This can happen when an existing database, having timelines planning elements,
        # gets migrated. During the migration, the existing planning elements are converted
        # to work_packages. Because the existance of a standard type cannot be guaranteed
        # during the migration, such work packages receive a type_id of nil.
        #
        # Because all work packages that do not have a type yet should always have had one
        # (from todays standpoint). The assignment is done covertedly.

        WorkPackage.transaction do
          green_color = colors[I18n.t(:default_color_green_light)]
          standard_type = Type.find_or_create_by(is_standard: true,
                                                 name: 'none',
                                                 position: 0,
                                                 color_id: green_color,
                                                 is_default: true,
                                                 is_in_roadmap: true,
                                                 in_aggregation: true,
                                                 is_milestone: false)

          # Adds the standard type to all existing projects
          #
          # As this seed might be executed on an existing database, there might be projects
          # that do not have the default type yet.

          condition = "NOT EXISTS
                         (SELECT * from projects_types
                          WHERE projects.id = projects_types.project_id
                          AND projects_types.type_id = #{standard_type.id})"

          projects_without_standard_type = Project.where(condition).all

          projects_without_standard_type.each do |project|
            project.types << standard_type
          end

          [WorkPackage, Journal::WorkPackageJournal].each do |klass|
            klass.where(type_id: nil).update_all(type_id: standard_type.id)
          end
        end
      end

      if Type.where(is_standard: false).any? || Status.any? || Workflow.any?
        puts '   *** Skipping types, statuses and workflows as there are already some configured'
      elsif Role.where(name: I18n.t(:default_role_member)).empty? ||
            Role.where(name: I18n.t(:default_role_project_admin)).empty?

        puts '   *** Skipping types, statuses and workflows as the required roles do not exist'
      else
        member = Role.where(name: I18n.t(:default_role_member)).first
        manager = Role.where(name: I18n.t(:default_role_project_admin)).first

        puts '   ↳ Types'
        TypeSeeder.new.seed!

        puts '   ↳ Statuses'
        StatusSeeder.new.seed!

        # Workflow - Each type has its own workflow
        workflows.each { |type_id, statuses_for_type|
          statuses_for_type.each { |old_status|
            statuses_for_type.each { |new_status|
              [manager.id, member.id].each { |role_id|
                Workflow.create type_id: type_id,
                                role_id: role_id,
                                old_status_id: old_status.id,
                                new_status_id: new_status.id
              }
            }
          }
        }
      end
    end

    def workflows
      types = Type.all
      types = types.map { |t| { t.name =>  t.id } }.reduce({}, :merge)

      new              = Status.find_by(name: I18n.t(:default_status_new))
      in_specification = Status.find_by(name: I18n.t(:default_status_in_specification))
      specified        = Status.find_by(name: I18n.t(:default_status_specified))
      confirmed        = Status.find_by(name: I18n.t(:default_status_confirmed))
      to_be_scheduled  = Status.find_by(name: I18n.t(:default_status_to_be_scheduled))
      scheduled        = Status.find_by(name: I18n.t(:default_status_scheduled))
      in_progress      = Status.find_by(name: I18n.t(:default_status_in_progress))
      in_development   = Status.find_by(name: I18n.t(:default_status_in_development))
      developed        = Status.find_by(name: I18n.t(:default_status_developed))
      in_testing       = Status.find_by(name: I18n.t(:default_status_in_testing))
      tested           = Status.find_by(name: I18n.t(:default_status_tested))
      test_failed      = Status.find_by(name: I18n.t(:default_status_test_failed))
      closed           = Status.find_by(name: I18n.t(:default_status_closed))
      on_hold          = Status.find_by(name: I18n.t(:default_status_on_hold))
      rejected         = Status.find_by(name: I18n.t(:default_status_rejected))

      {
        types[I18n.t(:default_type_task)]       => [new, in_progress, on_hold, rejected, closed],
        types[I18n.t(:default_type_milestone)]  => [new, to_be_scheduled, scheduled, in_progress, on_hold, rejected, closed],
        types[I18n.t(:default_type_phase)]      => [new, to_be_scheduled, scheduled, in_progress, on_hold, rejected, closed],
        types[I18n.t(:default_type_feature)]    => [new, in_specification, specified, in_development, developed, in_testing, tested, test_failed, on_hold, rejected, closed],
        types[I18n.t(:default_type_epic)]       => [new, in_specification, specified, in_development, developed, in_testing, tested, test_failed, on_hold, rejected, closed],
        types[I18n.t(:default_type_user_story)] => [new, in_specification, specified, in_development, developed, in_testing, tested, test_failed, on_hold, rejected, closed],
        types[I18n.t(:default_type_bug)]        => [new, confirmed, in_development, developed, in_testing, tested, test_failed, on_hold, rejected, closed]
      }
    end
  end
end
