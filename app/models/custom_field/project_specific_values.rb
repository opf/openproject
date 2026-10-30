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

module CustomField::ProjectSpecificValues
  extend ActiveSupport::Concern

  included do
    enum :project_specific_value_restriction, { allow: "allow", block: "block" }, prefix: true, validate: { allow_nil: true }
    has_many :project_specific_value_restrictions,
             class_name: "CustomField::ProjectSpecificValueRestriction",
             dependent: :delete_all
  end

  def restrictable_values
    list? ? custom_options : hierarchy_root.descendants
  end

  def usable_values_in(project)
    usable_values_in_any(Project.where(id: project))
  end

  def visible_values_for(user, within: nil)
    return restrictable_values if user.admin?

    projects = Project.with_visible_work_packages(user)
    projects = projects.where(id: within) if within

    usable_values_in_any(projects.with_available_custom_fields(id))
  end

  def usable_value_id?(project, value_id)
    return true if project_specific_value_restriction.nil?

    @usable_value_ids ||= {}
    @usable_value_ids[project.id] ||= usable_values_in(project).pluck(:id).to_set
    @usable_value_ids[project.id].include?(value_id.to_i)
  end

  def keep_usable_values(values, project)
    return values if project_specific_value_restriction.nil?

    usable_ids = usable_values_in(project).pluck(:id).map(&:to_s)
    values.is_a?(Array) ? values & usable_ids : values.presence_in(usable_ids)
  end

  def usable_value_counts_in(projects)
    count_sql = usable_values_in_reach("SELECT projects.id").unscope(:order).select(Arel.star.count).to_sql

    projects.unscope(:order).pluck(:id, Arel.sql("(#{count_sql})")).to_h
  end

  # SQL condition on whether the value with the id given by value_id_sql is usable in the project
  # selected (as id) by project_sql. Both may reference columns of the surrounding query.
  def usable_value_condition(value_id_sql, project_sql)
    "#{value_id_sql} IN (#{usable_values_in_reach(project_sql).select(:id).to_sql})"
  end

  private

  def usable_values_in_any(projects)
    usable_values_in_reach(projects.select(:id).to_sql)
  end

  # The restrictions are evaluated per project of the reach, so the rows of different projects
  # never combine into making a value usable that is usable in none of them.
  def usable_values_in_reach(reach_sql)
    return restrictable_values if project_specific_value_restriction.nil?

    restrictable_values.where(<<~SQL.squish)
      EXISTS (
        SELECT 1 FROM (#{reach_sql}) reach
        WHERE #{list? ? usable_option_condition : usable_item_condition}
      )
    SQL
  end

  def usable_option_condition
    listed = "EXISTS (#{listed_in_reach(:custom_option_id, 'custom_options.id')})"

    project_specific_value_restriction_allow? ? listed : "NOT #{listed}"
  end

  # An item is only usable if it and all of its ancestors below the hierarchy root are.
  def usable_item_condition
    if project_specific_value_restriction_allow?
      <<~SQL.squish
        NOT EXISTS (
          SELECT 1 FROM hierarchical_item_hierarchies path
          JOIN hierarchical_items ancestor ON ancestor.id = path.ancestor_id
          WHERE path.descendant_id = hierarchical_items.id
            AND ancestor.parent_id IS NOT NULL
            AND NOT EXISTS (#{listed_in_reach(:hierarchy_item_id, 'path.ancestor_id')})
        )
      SQL
    else
      <<~SQL.squish
        NOT EXISTS (
          SELECT 1 FROM hierarchical_item_hierarchies path
          WHERE path.descendant_id = hierarchical_items.id
            AND EXISTS (#{listed_in_reach(:hierarchy_item_id, 'path.ancestor_id')})
        )
      SQL
    end
  end

  def listed_in_reach(value_column, value_expression)
    table = CustomField::ProjectSpecificValueRestriction.table_name

    project_specific_value_restrictions
      .where(restriction: project_specific_value_restriction)
      .where("#{table}.project_id = reach.id AND #{table}.#{value_column} = #{value_expression}")
      .select(1)
      .to_sql
  end
end
