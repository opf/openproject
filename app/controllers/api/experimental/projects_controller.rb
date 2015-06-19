#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module Api
  module Experimental
    class ProjectsController < ApplicationController
      include ::Api::Experimental::ApiController

      before_filter :find_project,
                    :authorize, except: [:index]
      before_filter :authorize_global, only: [:index]

      def index
        # Note: Ordering by project hierarchy by default
        @projects = []
        Project.project_tree(Project.visible) do |project, _level|
          @projects << project
        end

        respond_to do |format|
          format.api
        end
      end

      def show
        respond_to do |format|
          format.api
        end
      end

      def sub_projects
        @sub_projects = @project.descendants.visible

        respond_to do |format|
          format.api
        end
      end

      private

      def find_project
        @project = Project.where(identifier: params[:project_id]).first ||
                   Project.find(params[:id])
      end
    end
  end
end
