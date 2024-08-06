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

module WorkPackages::Scopes::LeftJoinSelfAndDescendants
  extend ActiveSupport::Concern

  class_methods do
    def left_join_self_and_descendants(user, work_package = nil)
      joins(join_descendants(user, work_package).join_sources)
    end

    private

    def join_descendants(user, work_package)
      wp_table
        .outer_join(hierarchies_table)
        .on(hierarchies_join_condition(work_package))
        .outer_join(wp_descendants_table)
        .on(hierarchy_and_allowed_condition(user))
    end

    def hierarchy_of_wp_condition
      wp_table[:id].eq(hierarchies_table[:ancestor_id])
    end

    def hierarchies_join_condition(work_package)
      if work_package
        hierarchy_of_wp_condition
          .and(wp_table[:id].eq(work_package.id))
      else
        hierarchy_of_wp_condition
      end
    end

    def hierarchy_and_allowed_condition(user)
      self_or_descendant_condition
        .and(allowed_to_view_work_packages(user))
    end

    def allowed_to_view_work_packages(user)
      wp_descendants_table[:project_id].in(Project.allowed_to(user, :view_work_packages).select(:id).arel).or(
        wp_descendants_table[:id].in(WorkPackage.visible(user).select(:id).arel)
      )
    end

    def self_or_descendant_condition
      hierarchies_table[:descendant_id].eq(wp_descendants_table[:id])
    end

    def wp_table
      @wp_table ||= WorkPackage.arel_table
    end

    def hierarchies_table
      @relations || WorkPackageHierarchy.arel_table
    end

    def wp_descendants_table
      @wp_descendants_table ||= wp_table.alias("descendants")
    end
  end
end
