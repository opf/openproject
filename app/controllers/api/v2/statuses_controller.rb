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

# resolves either a given status (show) or returns a list of available statuses
# if the controller is called nested inside a project, it returns only the
# statuses that can be reached by the workflows of the project
module Api
  module V2
    class StatusesController < ApplicationController
      include PaginationHelper

      include ::Api::V2::ApiController
      rescue_from ActiveRecord::RecordNotFound, with: lambda { render_404 }

      before_action :resolve_project
      accept_key_auth :index, :show

      def index
        @statuses = Status.all

        respond_to do |format|
          format.api
        end
      end

      def show
        @status = Status.find(params[:id])

        respond_to do |format|
          format.api
        end
      end

      protected

      def resolve_project
        @project = Project.find(params[:project_id]) if params[:project_id]
      end
    end
  end
end
