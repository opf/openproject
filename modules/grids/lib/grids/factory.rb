#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

module Grids
  class Factory
    class << self
      def build(scope, user)
        attributes = ::Grids::Configuration.attributes_from_scope(scope)

        grid_class = attributes[:class]
        grid_project = project_from_id(attributes[:project_id])

        new_default(grid_class, grid_project, user)
      end

      private

      def new_default(klass, project, user)
        params = class_defaults(klass)

        if klass.reflect_on_association(:project)
          params[:project] = project
        end

        if klass.reflect_on_association(:user)
          params[:user] = user
        end

        klass.new(params)
      end

      def class_defaults(klass)
        params = ::Grids::Configuration.defaults(klass)

        params || { row_count: 4, column_count: 5, widgets: [] }
      end

      def project_from_id(id)
        Project.find(id) if id
      rescue ActiveRecord::RecordNotFound
        nil
      end
    end
  end
end
