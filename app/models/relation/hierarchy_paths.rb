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

module Relation::HierarchyPaths
  extend ActiveSupport::Concern

  included do
    after_create :add_hierarchy_path
    after_destroy :remove_hierarchy_path
    after_update :update_hierarchy_path

    def self.rebuild_hierarchy_paths!
      execute_sql remove_hierarchy_path_sql
      execute_sql add_hierarchy_path_sql
    end

    def self.execute_sql(sql)
      ActiveRecord::Base.connection.execute sql
    end

    private

    def add_hierarchy_path
      return unless hierarchy?

      self.class.execute_sql self.class.add_hierarchy_path_sql(to_id)
    end

    def remove_hierarchy_path
      self.class.execute_sql self.class.remove_hierarchy_path_sql(to_id)
      self.class.execute_sql self.class.add_hierarchy_path_sql(to_id)
    end

    def update_hierarchy_path
      if was_hierarchy_relation?
        remove_hierarchy_path
      elsif now_hierarchy_relation_or_former_id_changed?
        add_hierarchy_path
      elsif hierarchy_relatin_and_to_id_changed?
        alter_hierarchy_path
      end
    end

    def was_hierarchy_relation?
      relation_type_changed? && relation_type_was == Relation::TYPE_HIERARCHY
    end

    def now_hierarchy_relation_or_former_id_changed?
      (relation_type_changed? || from_id_changed?) && hierarchy?
    end

    def hierarchy_relatin_and_to_id_changed?
      hierarchy? && to_id_changed?
    end

    def alter_hierarchy_path
      self.class.execute_sql self.class.remove_hierarchy_path_sql(to_id_was)
      self.class.execute_sql self.class.add_hierarchy_path_sql(to_id)
    end

    def self.add_hierarchy_path_sql(id = nil)
      <<-SQL
        INSERT INTO
          #{hierarchy_table_name}
          (work_package_id, path)
        SELECT
          to_id, #{add_hierarchy_agg_function} AS path
          FROM
          (SELECT to_id, from_id, hierarchy
          FROM relations
          WHERE hierarchy > 0 AND relates = 0 AND blocks = 0 AND duplicates = 0 AND includes = 0 AND requires = 0 AND follows = 0
          #{add_hierarchy_id_constraint(id)}
          ) ordered_by_hierarchy
          GROUP BY to_id
        #{add_hierarchy_conflict_statement}
      SQL
    end

    def self.remove_hierarchy_path_sql(id = nil)
      id_constraint = if id
                        "WHERE work_package_id = #{id}"
                      end

      <<-SQL
        DELETE FROM
        #{hierarchy_table_name}
        #{id_constraint}
      SQL
    end

    def self.add_hierarchy_id_constraint(id)
      if id
        <<-SQL
          AND (to_id = #{id}
               OR to_id IN (#{Relation.hierarchy.where(from_id: id).select(:to_id).to_sql}))
        SQL
      end
    end

    def self.add_hierarchy_conflict_statement
      if ActiveRecord::Base.connection.adapter_name == 'Mysql2'
        "ON DUPLICATE KEY
         UPDATE #{hierarchy_table_name}.path = VALUES(path)"
      else
        "ON CONFLICT (work_package_id)
         DO UPDATE SET path = EXCLUDED.path"
      end
    end

    def self.add_hierarchy_agg_function
      if ActiveRecord::Base.connection.adapter_name == 'Mysql2'
        "GROUP_CONCAT(from_id ORDER BY hierarchy DESC SEPARATOR ',')"
      else
        "string_agg(from_id::TEXT, ',' ORDER BY hierarchy DESC)"
      end
    end

    def self.hierarchy_table_name
      'hierarchy_paths'
    end
  end
end
