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

require "story"
require "task"

module OpenProject::Backlogs
  class WorkPackageFilter < ::Queries::WorkPackages::Filter::WorkPackageFilter
    def allowed_values
      [[I18n.t("backlogs.story"), "story"],
       [I18n.t("backlogs.task"), "task"],
       [I18n.t("backlogs.impediment"), "impediment"],
       [I18n.t("backlogs.any"), "any"]]
    end

    def available?
      backlogs_enabled? &&
        backlogs_configured?
    end

    def self.key
      :backlogs_work_package_type
    end

    def where
      sql_for_field(values)
    end

    def type
      :list
    end

    def human_name
      WorkPackage.human_attribute_name(:backlogs_work_package_type)
    end

    def dependency_class
      "::API::V3::Queries::Schemas::BacklogsTypeDependencyRepresenter"
    end

    def ar_object_filter?
      true
    end

    def value_objects
      available_backlog_types = allowed_values.index_by(&:last)

      values
        .filter_map { |backlog_type_id| available_backlog_types[backlog_type_id] }
        .map { |value| BacklogsType.new(*value) }
    end

    private

    def backlogs_configured?
      Story.types.present? && Task.type.present?
    end

    def backlogs_enabled?
      project.nil? || project.module_enabled?(:backlogs)
    end

    def sql_for_field(values)
      selected_values = if values.include?("any")
                          ["story", "task"]
                        else
                          values
                        end

      sql_parts = selected_values.map do |val|
        case val
        when "story"
          sql_for_story
        when "task"
          sql_for_task
        when "impediment"
          sql_for_impediment
        end
      end

      case operator
      when "="
        sql_parts.join(" OR ")
      when "!"
        "NOT (" + sql_parts.join(" OR ") + ")"
      end
    end

    def db_table
      WorkPackage.table_name
    end

    def sql_for_story
      story_types = Story.types.map(&:to_s).join(",")

      "(#{db_table}.type_id IN (#{story_types}))"
    end

    def sql_for_task
      <<-SQL
      (#{db_table}.type_id = #{Task.type} AND
       #{db_table}.id IN (#{is_child_sql}))
      SQL
    end

    def sql_for_impediment
      <<-SQL
        (#{db_table}.type_id = #{Task.type} AND
         #{db_table}.id IN (#{blocks_backlogs_type_sql})
         AND #{db_table}.id NOT IN (#{is_child_sql}))
      SQL
    end

    def is_child_sql
      Relation
        .hierarchy
        .select(:to_id)
        .to_sql
    end

    def blocks_backlogs_type_sql
      all_types = (Story.types + [Task.type]).map(&:to_s)

      Relation
        .blocks
        .joins(:to)
        .where(work_packages: { type_id: all_types })
        .select(:to_id)
        .to_sql
    end
  end

  # Need to be conformant to the interface required
  # by api/v3/queries/filters/query_filter_instance_representer.rb
  class BacklogsType
    attr_accessor :id,
                  :name

    def initialize(name, id)
      self.id = id
      self.name = name
    end
  end
end
