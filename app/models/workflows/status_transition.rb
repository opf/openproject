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

class Workflows::StatusTransition < ApplicationRecord
  belongs_to :role, inverse_of: :workflow_status_transitions
  belongs_to :old_status, class_name: "Status", inverse_of: :workflow_status_transitions
  belongs_to :new_status, class_name: "Status"
  belongs_to :workflow, inverse_of: :status_transitions

  validates :role, :old_status, :new_status, :workflow, presence: true

  def self.count_by_workflow_and_role
    counts = counts_per_workflow_and_role
    roles = Role.order(Arel.sql("builtin, position"))

    ::Workflow.in_display_order.map do |workflow|
      [workflow, roles.map { |role| [role, counts.fetch([role.id, workflow.id], 0)] }]
    end
  end

  def self.counts_per_workflow_and_role
    connection
      .select_all("SELECT role_id, workflow_id, count(id) AS c FROM #{table_name} GROUP BY role_id, workflow_id")
      .to_h { |row| [[row["role_id"].to_i, row["workflow_id"].to_i], row["c"].to_i] }
  end

  def self.from_status(old_status_id, role_ids, author: false, assignee: false)
    workflows = where(old_status_id:, role_id: role_ids)

    if author && assignee
      workflows
    elsif author || assignee
      workflows
        .merge(where(author:).or(where(assignee:)))
    else
      workflows
        .where(author:)
        .where(assignee:)
    end
  end

  def self.available_statuses(project, user = User.current)
    includes(:new_status)
      .where(role_id: user.roles_for_project(project).map(&:id))
      .filter_map(&:new_status)
      .uniq
      .sort
  end

  def self.copy(source_workflow, source_role, target_workflows, target_roles)
    unless source_workflow.is_a?(::Workflow) || source_role.is_a?(Role)
      raise ArgumentError.new("source_workflow or source_role must be specified")
    end

    workflows = copy_collection(target_workflows, ::Workflow)
    roles = copy_collection(target_roles, Role)

    transaction do
      workflows.each do |target_workflow|
        roles.each do |target_role|
          copy_one(source_workflow || target_workflow,
                   source_role || target_role,
                   target_workflow,
                   target_role)
        end
      end
    end
  end

  def self.copy_collection(records, model)
    records = Array(records)
    records.empty? ? model.all : records
  end

  def self.copy_one(source_workflow, source_role, target_workflow, target_role) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Naming/PredicateMethod
    unless source_workflow.is_a?(::Workflow) && !source_workflow.new_record? &&
           source_role.is_a?(Role) && !source_role.new_record? &&
           target_workflow.is_a?(::Workflow) && !target_workflow.new_record? &&
           target_role.is_a?(Role) && !target_role.new_record?

      raise ArgumentError.new("arguments can not be nil or unsaved objects")
    end

    if source_workflow.id == target_workflow.id && source_role == target_role
      false
    else
      transaction do
        where(workflow_id: target_workflow.id, role_id: target_role.id).delete_all
        connection.insert <<~SQL.squish
          INSERT INTO #{table_name} (workflow_id, role_id, old_status_id, new_status_id, author, assignee)
          SELECT #{target_workflow.id}, #{target_role.id}, old_status_id, new_status_id, author, assignee
          FROM #{table_name}
          WHERE workflow_id = #{source_workflow.id} AND role_id = #{source_role.id}
        SQL
      end
      true
    end
  end

  def self.eligible_roles
    roles = Role.where(type: ProjectRole.name)

    if EnterpriseToken.allows_to?(:work_package_sharing)
      roles.or(Role.where(builtin: Role::BUILTIN_WORK_PACKAGE_EDITOR))
    else
      roles
    end
  end

  def self.ordered_eligible_roles
    eligible_roles.order(:builtin, :position)
  end

  def self.selected_roles(role_ids)
    ordered = ordered_eligible_roles
    selected = ordered.where(id: role_ids)
    selected.any? ? selected : [ordered.first].compact
  end
end
