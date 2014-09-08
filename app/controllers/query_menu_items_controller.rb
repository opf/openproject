#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
  before_filter :load_project_and_query
  before_filter :authorize

  def create
    @query_menu_item = MenuItems::QueryMenuItem.find_or_initialize_by_name_and_navigatable_id @query.normalized_name, @query.id, title: @query.name
    if @query_menu_item.save
      flash[:notice] = l(:notice_successful_create)
    else
      flash[:error] = l(:error_menu_item_not_created)
    end

    redirect_to query_path
  end

  def update
    @query_menu_item = MenuItems::QueryMenuItem.find params[:id]

    if @query_menu_item.update_attributes query_menu_item_params
      flash[:notice] = l(:notice_successful_update)
    else
      flash[:error] = l(:error_menu_item_not_saved)
    end

    redirect_to query_path
  end

  def destroy
    @query_menu_item = MenuItems::QueryMenuItem.find params[:id]

    @query_menu_item.destroy
    flash[:notice] = l(:notice_successful_delete)

    redirect_to query_path
  end

  def edit
    @query_menu_item = MenuItems::QueryMenuItem.find params[:id]
  end

  private

  def load_project_and_query
    @project = Project.find params[:project_id]
    @query = Query.find params[:query_id]
  end

  def query_path
    project_work_packages_path(@project, :query_id => @query.id)
  end

  def normalized_query_name
    @query.name.parameterize.underscore
  end

  # inherit permissions from queries where create and update are performed bei new and edit actions
  def authorize(ctrl = 'queries', action = params[:action], global = false)
    action = case action
             when 'create'
               'new'
             when 'update'
               'edit'
             else
               action
             end

    super
  end

  def query_menu_item_params
    params.require(:menu_items_query_menu_item).permit(:name, :title, :navigatable_id, :parent_id)
  end
end
