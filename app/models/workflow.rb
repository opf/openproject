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

class Workflow < ApplicationRecord
  belongs_to :role
  belongs_to :old_status, class_name: "Status"
  belongs_to :new_status, class_name: "Status"
  belongs_to :type_variant, inverse_of: "own_workflows"

  validates :role, :old_status, :new_status, presence: true

  # Returns workflow transitions count by variant and role
  def self.count_by_type_variant_and_role # rubocop:disable Metrics/AbcSize
    counts = connection.select_all(
      "SELECT role_id, type_variant_id, count(id) AS c FROM #{Workflow.table_name} GROUP BY role_id, type_variant_id"
    )
    roles = Role.order(Arel.sql("builtin, position"))
    variants = ::TypeVariant.joins(:type).merge(::Type.order(Arel.sql("position"))).in_display_order

    variants.map do |variant|
      counts_per_role = roles.map do |role|
        row = counts.detect do |c|
          c["role_id"].to_s == role.id.to_s && c["type_variant_id"].to_s == variant.id.to_s
        end
        [role, (row.nil? ? 0 : row["c"].to_i)]
      end

      [variant, counts_per_role]
    end
  end

  # Gets all work flows originating from the provided status that are defined for any of the roles.
  # Workflows specific to author or assignee are ignored unless author and/or assignee are set to true. In
  # such a case, those work flows are additionally returned.
  def self.from_status(old_status_id, role_ids, author: false, assignee: false)
    workflows = where(old_status_id:, role_id: role_ids)

    if author && assignee
      workflows
    elsif author || assignee
      workflows
        .merge(Workflow.where(author:).or(Workflow.where(assignee:)))
    else
      workflows
        .where(author:)
        .where(assignee:)
    end
  end

  # Find potential statuses the user could be allowed to switch issues to
  def self.available_statuses(project, user = User.current)
    Workflow
      .includes(:new_status)
      .where(role_id: user.roles_for_project(project).map(&:id))
      .filter_map(&:new_status)
      .uniq
      .sort
  end

  # Copies workflows from source to targets
  def self.copy(source_variant, source_role, target_variants, target_roles) # rubocop:disable Metrics/PerceivedComplexity
    unless source_variant.is_a?(::TypeVariant) || source_role.is_a?(Role)
      raise ArgumentError.new("source_variant or source_role must be specified")
    end

    target_variants = Array(target_variants)
    target_variants = ::TypeVariant.all if target_variants.empty?

    target_roles = Array(target_roles)
    target_roles = Role.all if target_roles.empty?

    target_variants.each do |target_variant|
      target_roles.each do |target_role|
        copy_one(source_variant || target_variant,
                 source_role || target_role,
                 target_variant,
                 target_role)
      end
    end
  end

  # Copies a single set of workflows from source to target.
  # Returns false when source and target are the same, true after a successful copy.
  def self.copy_one(source_variant, source_role, target_variant, target_role) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Naming/PredicateMethod
    unless source_variant.is_a?(::TypeVariant) && !source_variant.new_record? &&
           source_role.is_a?(Role) && !source_role.new_record? &&
           target_variant.is_a?(::TypeVariant) && !target_variant.new_record? &&
           target_role.is_a?(Role) && !target_role.new_record?

      raise ArgumentError.new("arguments can not be nil or unsaved objects")
    end

    if source_variant == target_variant && source_role == target_role
      false
    else
      transaction do
        where(type_variant_id: target_variant.id, role_id: target_role.id).delete_all
        connection.insert <<~SQL.squish
          INSERT INTO #{Workflow.table_name} (type_variant_id, role_id, old_status_id, new_status_id, author, assignee)
          SELECT #{target_variant.id}, #{target_role.id}, old_status_id, new_status_id, author, assignee
          FROM #{Workflow.table_name}
          WHERE type_variant_id = #{source_variant.id} AND role_id = #{source_role.id}
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
