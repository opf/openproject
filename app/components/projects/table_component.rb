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

module Projects
  class TableComponent < Tables::QueryComponent
    self.eager_load = :enabled_modules

    def columns
      @columns ||= begin
        columns = super

        index = columns.index { |column| column.attribute == :name }
        columns.insert(index, ::Queries::Projects::Selects::Default.new(:lft)) if index

        columns
      end
    end

    def highlight_column?(column)
      return false if column.attribute == :lft

      super
    end

    # We don't return the project row
    # but the [project, level] array from the helper
    def render_rows
      render(Projects::RowComponent.with_collection(to_enum(:projects_with_levels_order_sensitive, rows).to_a,
                                                    table: self))
    end

    def projects_with_levels_order_sensitive(projects, &)
      if sorted_by_lft?
        Project.project_tree(projects, &)
      else
        projects_with_level(projects, &)
      end
    end

    def projects_with_level(projects, &)
      ancestors = []

      projects.each do |project|
        while !ancestors.empty? && !project.is_descendant_of?(ancestors.last)
          ancestors.pop
        end

        yield project, ancestors.count

        ancestors << project
      end
    end

    def favored_project_ids
      @favored_project_ids ||= Favorite.where(user: current_user, favored_type: "Project").pluck(:favored_id)
    end

    def sorted_by_lft?
      query.orders.first&.attribute == :lft
    end
  end
end
