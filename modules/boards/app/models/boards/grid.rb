#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require_dependency 'grids/grid'

module Boards
  class Grid < ::Grids::Grid
    belongs_to :project

    def self.new_default(user: nil, project:)
      new(
        project: project,
        row_count: 1,
        column_count: 4,
        widgets: []
      )
    end

    def writable?(user)
      super &&
        Project.allowed_to(user, :manage_boards).exists?(project_id)
    end

    class << self
      alias_method :super_visible, :visible

      def visible(user = User.current)
        in_project_with_permission(user, :view_boards)
          .or(in_project_with_permission(user, :manage_boards))
      end

      private

      def in_project_with_permission(user, permission)
        super_visible
          .where(project_id: Project.allowed_to(user, permission))
      end
    end

    private_class_method :super_visible
  end
end
