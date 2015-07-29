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
#++

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
    standard_type = Type.find_or_create_by_is_standard(true, name: 'none',
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
  puts '***** Skipping types, statuses and workflows as there are already some configured'
elsif Role.where(name: I18n.t(:default_role_member)).empty? ||
      Role.where(name: I18n.t(:default_role_project_admin)).empty?

  puts '***** Skipping types, statuses and workflows as the required roles do not exist'
else

  Type.transaction do
    task = Type.new.tap do |type|
      type.name = I18n.t(:default_type_task)
      type.color_id = colors[I18n.t(:default_color_grey)]
      type.is_default = true
      type.is_in_roadmap = true
      type.in_aggregation = false
      type.is_milestone = false
      type.position = 1
    end

    task.save!

    milestone = Type.new.tap do |type|
      type.name = I18n.t(:default_type_milestone)
      type.color_id = colors[I18n.t(:default_color_green_light)]
      type.is_default = false
      type.is_in_roadmap = false
      type.in_aggregation = true
      type.is_milestone = true
      type.position = 2
    end

    milestone.save!

    phase = Type.new.tap do |type|
      type.name = I18n.t(:default_type_phase)
      type.color_id = colors[I18n.t(:default_color_blue_dark)]
      type.is_default = false
      type.is_in_roadmap = false
      type.in_aggregation = true
      type.is_milestone = false
      type.position = 3
    end

    phase.save!

    feature = Type.new.tap do |type|
      type.name = I18n.t(:default_type_feature)
      type.color_id = colors[I18n.t(:default_color_blue)]
      type.is_default = false
      type.is_in_roadmap = true
      type.in_aggregation = false
      type.is_milestone = false
      type.position = 4
    end

    feature.save!

    epic = Type.new.tap do |type|
      type.name = I18n.t(:default_type_epic)
      type.color_id = colors[I18n.t(:default_color_orange)]
      type.is_default = false
      type.is_in_roadmap = true
      type.in_aggregation = true
      type.is_milestone = false
      type.position = 5
    end

    epic.save!

    user_story = Type.new.tap do |type|
      type.name = I18n.t(:default_type_user_story)
      type.color_id = colors[I18n.t(:default_color_grey_dark)]
      type.is_default = false
      type.is_in_roadmap = true
      type.in_aggregation = false
      type.is_milestone = false
      type.position = 6
    end

    user_story.save!

    bug = Type.new.tap do |type|
      type.name = I18n.t(:default_type_bug)
      type.is_default = false
      type.color_id = colors[I18n.t(:default_color_red)]
      type.is_in_roadmap = true
      type.in_aggregation = false
      type.is_milestone = false
      type.position = 7
    end

    bug.save!

    new = Status.new.tap do |type|
      type.name = I18n.t(:default_status_new)
      type.is_closed = false
      type.is_default = true
      type.position = 1
    end

    new.save!

    in_specification = Status.new.tap do |type|
      type.name = I18n.t(:default_status_in_specification)
      type.is_closed = false
      type.is_default = false
      type.position = 2
    end

    in_specification.save!

    specified = Status.new.tap do |type|
      type.name = I18n.t(:default_status_specified)
      type.is_closed = false
      type.is_default = false
      type.position = 3
    end

    specified.save!

    confirmed = Status.new.tap do |type|
      type.name = I18n.t(:default_status_confirmed)
      type.is_closed = false
      type.is_default = false
      type.position = 4
    end

    confirmed.save!

    to_be_scheduled = Status.new.tap do |type|
      type.name = I18n.t(:default_status_to_be_scheduled)
      type.is_closed = false
      type.is_default = false
      type.position = 5
    end

    to_be_scheduled.save!

    scheduled = Status.new.tap do |type|
      type.name = I18n.t(:default_status_scheduled)
      type.is_closed = false
      type.is_default = false
      type.position = 6
    end

    scheduled.save!

    in_progress = Status.new.tap do |type|
      type.name = I18n.t(:default_status_in_progress)
      type.is_closed = false
      type.is_default = false
      type.position = 7
    end

    in_progress.save!

    in_development = Status.new.tap do |type|
      type.name = I18n.t(:default_status_in_development)
      type.is_closed = false
      type.is_default = false
      type.position = 8
    end

    in_development.save!

    developed = Status.new.tap do |type|
      type.name = I18n.t(:default_status_developed)
      type.is_closed = false
      type.is_default = false
      type.position = 9
    end

    developed.save!

    in_testing = Status.new.tap do |type|
      type.name = I18n.t(:default_status_in_testing)
      type.is_closed = false
      type.is_default = false
      type.position = 10
    end

    in_testing.save!

    tested = Status.new.tap do |type|
      type.name = I18n.t(:default_status_tested)
      type.is_closed = false
      type.is_default = false
      type.position = 11
    end

    tested.save!

    test_failed = Status.new.tap do |type|
      type.name = I18n.t(:default_status_test_failed)
      type.is_closed = false
      type.is_default = false
      type.position = 12
    end

    test_failed.save!

    closed = Status.new.tap do |type|
      type.name = I18n.t(:default_status_closed)
      type.is_closed = true
      type.is_default = false
      type.position = 13
    end

    closed.save!

    on_hold = Status.new.tap do |type|
      type.name = I18n.t(:default_status_on_hold)
      type.is_closed = false
      type.is_default = false
      type.position = 14
    end

    on_hold.save!

    rejected = Status.new.tap do |type|
      type.name = I18n.t(:default_status_rejected)
      type.is_default = false
      type.is_closed = true
      type.position = 15
    end

    rejected.save!

    member = Role.where(name: I18n.t(:default_role_member)).first
    manager = Role.where(name: I18n.t(:default_role_project_admin)).first

    # Workflow - Each type has its own workflow
    workflows = { task.id =>       [new,
                                    in_progress,
                                    on_hold,
                                    rejected,
                                    closed],
                  milestone.id =>  [new,
                                    to_be_scheduled,
                                    scheduled,
                                    in_progress,
                                    on_hold,
                                    rejected,
                                    closed],
                  phase.id =>      [new,
                                    to_be_scheduled,
                                    scheduled,
                                    in_progress,
                                    on_hold,
                                    rejected,
                                    closed],
                  feature.id =>    [new,
                                    in_specification,
                                    specified,
                                    in_development,
                                    developed,
                                    in_testing,
                                    tested,
                                    test_failed,
                                    on_hold,
                                    rejected,
                                    closed],
                  epic.id =>       [new,
                                    in_specification,
                                    specified,
                                    in_development,
                                    developed,
                                    in_testing,
                                    tested,
                                    test_failed,
                                    on_hold,
                                    rejected,
                                    closed],
                  user_story.id => [new,
                                    in_specification,
                                    specified,
                                    in_development,
                                    developed,
                                    in_testing,
                                    tested,
                                    test_failed,
                                    on_hold,
                                    rejected,
                                    closed],
                  bug.id =>        [new,
                                    confirmed,
                                    in_development,
                                    developed,
                                    in_testing,
                                    tested,
                                    test_failed,
                                    on_hold,
                                    rejected,
                                    closed] }

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
