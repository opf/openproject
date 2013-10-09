#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

class QueryMenuItemsController < ApplicationController
	before_filter :load_query

	def create
		@query_menu_item = MenuItems::QueryMenuItem.new :navigatable_id => @query.id, :title => @query.name, :name => @query.name

		if @query_menu_item.save
			flash[:notice] = l(:notice_successful_create)
    else
			flash[:error] = l(:error_menu_item_not_created)
		end

  	redirect_to query_path
	end

	def destroy
		@query_menu_item = MenuItems::QueryMenuItem.find params[:id]

		@query_menu_item.destroy
		flash[:notice] = l(:notice_successful_delete)

		redirect_to query_path
	end

	private

	def load_query
		@query = Query.find params[:query_id]
	end

	def query_path
		project = Project.find(params[:project_id])
		project_work_packages_path(project, :query_id => @query.id)
	end
end
