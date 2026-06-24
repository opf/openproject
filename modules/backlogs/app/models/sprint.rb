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

class Sprint < ApplicationRecord
  include ::Scopes::Scoped

  belongs_to :project
  has_many :work_packages, inverse_of: :sprint, dependent: :nullify
  has_many :goals,
           class_name: "SprintGoal",
           inverse_of: :sprint,
           dependent: :delete_all

  accepts_nested_attributes_for :goals,
                                allow_destroy: true,
                                reject_if: ->(attributes) {
                                  attributes["id"].blank? && attributes["text"].blank?
                                },
                                limit: 1

  has_many :task_boards,
           as: :linked,
           class_name: "Boards::Grid",
           inverse_of: :linked,
           dependent: :nullify

  scopes :assignable,
         :for_project,
         :not_completed,
         :order_by_date,
         :receiving_projects,
         :visible,
         :native_to_sprint_source

  enum :status,
       {
         in_planning: "in_planning",
         active: "active",
         completed: "completed"
       },
       default: "in_planning",
       validate: true

  validates :name, :project, presence: true
  validates :start_date, :finish_date, presence: true, if: :active?
  validates :finish_date,
            comparison: { greater_than_or_equal_to: :start_date },
            if: :date_range_set?

  validates :status,
            uniqueness: {
              scope: :project_id,
              conditions: -> { active },
              message: :only_one_active_sprint_allowed
            },
            if: :active?

  def date_range_set?
    start_date? && finish_date?
  end

  def duration
    return nil unless date_range_set?

    Day.working.from_range(from: start_date, to: finish_date).count
  end

  def task_board_for(project)
    task_boards.find { it.project_id == project.id }
  end

  def work_packages_for(project)
    work_packages.where(project:).order_by_position
  end

  def owned_by?(project)
    project_id == project.id
  end

  def shared_with?(project)
    self.class.for_project(project).exists?(id:) && !owned_by?(project)
  end

  def visible_to?(project)
    self.class.for_project(project).exists?(id:)
  end

  def goal_for(project)
    goals.find { |goal| goal.project_id == project.id }
  end

  def goal_text_for(project)
    goal_for(project)&.text
  end

  def to_s = name
end
