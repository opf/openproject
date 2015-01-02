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
  module V2
    class PlanningElementTypesController < TypesController
      include ::Api::V2::ApiController

      # Before filters are inherited from TypesController.
      # However we do want non admins to access the actions.
      skip_before_filter :require_admin
      before_filter :find_optional_project

      accept_key_auth :index, :show

      def index
        @types = (@project.nil?) ? Type.all : @project.types

        respond_to do |format|
          format.api
        end
      end

      def show
        @type = if @project.nil?
                  Type.find_by_id(params[:id])
                else
                  @project.types.find_by_id(params[:id])
                end

        if @type
          respond_to do |format|
            format.api
          end
        else
          render_404
        end
      end
    end
  end
end
