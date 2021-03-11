#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
#++

module WorkPackages::Scopes::LeftJoinSelfAndDescendants
  extend ActiveSupport::Concern

  class_methods do
    def left_join_self_and_descendants(user, work_package = nil)
      joins(join_descendants(user, work_package).join_sources)
    end

    private

    def join_descendants(user, work_package)
      wp_table
        .outer_join(relations_table)
        .on(relations_join_descendants_condition(work_package))
        .outer_join(wp_descendants)
        .on(hierarchy_and_allowed_condition(user))
    end

    def relations_from_and_type_matches_condition
      relations_join_condition = relation_of_wp_and_hierarchy_condition

      non_hierarchy_type_columns.each do |type|
        relations_join_condition = relations_join_condition.and(relations_table[type].eq(0))
      end

      relations_join_condition
    end

    def relation_of_wp_and_hierarchy_condition
      wp_table[:id].eq(relations_table[:from_id]).and(relations_table[:hierarchy].gteq(0))
    end

    def relations_join_descendants_condition(work_package)
      if work_package
        relations_from_and_type_matches_condition
          .and(wp_table[:id].eq(work_package.id))
      else
        relations_from_and_type_matches_condition
      end
    end

    def hierarchy_and_allowed_condition(user)
      self_or_descendant_condition
        .and(allowed_to_view_work_packages(user))
    end

    def allowed_to_view_work_packages(user)
      wp_descendants[:project_id].in(Project.allowed_to(user, :view_work_packages).select(:id).arel)
    end

    def self_or_descendant_condition
      relations_table[:to_id].eq(wp_descendants[:id])
    end

    def non_hierarchy_type_columns
      TypedDag::Configuration[WorkPackage].type_columns - [:hierarchy]
    end

    def wp_table
      @wp_table ||= WorkPackage.arel_table
    end

    def relations_table
      @relations || Relation.arel_table
    end

    def wp_descendants
      @wp_descendants ||= wp_table.alias('descendants')
    end
  end
end
