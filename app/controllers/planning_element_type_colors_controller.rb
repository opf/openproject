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

class PlanningElementTypeColorsController < ApplicationController
  helper :timelines

  before_action :disable_api
  before_action :require_admin_unless_readonly_api_request

  accept_key_auth :index, :show

  helper :timelines
  layout 'admin'

  menu_item :colors

  def index
    @colors = PlanningElementTypeColor.all
    respond_to do |format|
      format.html
    end
  end

  def show
    @color = PlanningElementTypeColor.find(params[:id])
    respond_to do |_format|
    end
  end

  def new
    @color = PlanningElementTypeColor.new
    respond_to do |format|
      format.html
    end
  end

  def create
    @color = PlanningElementTypeColor.new(permitted_params.color)

    if @color.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to colors_path
    else
      flash.now[:error] = l('timelines.color_could_not_be_saved')
      render action: 'new'
    end
  end

  def edit
    @color = PlanningElementTypeColor.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def update
    @color = PlanningElementTypeColor.find(params[:id])

    if @color.update_attributes(permitted_params.color)
      flash[:notice] = l(:notice_successful_update)
      redirect_to colors_path
    else
      flash.now[:error] = l('timelines.color_could_not_be_saved')
      render action: 'edit'
    end
  end

  def move
    @color = PlanningElementTypeColor.find(params[:id])

    if @color.update_attributes(permitted_params.color_move)
      flash[:notice] = l(:notice_successful_update)
    else
      render action: 'edit'
    end
    redirect_to colors_path
  end

  def confirm_destroy
    @color = PlanningElementTypeColor.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def destroy
    @color = PlanningElementTypeColor.find(params[:id])
    @color.destroy

    flash[:notice] = l(:notice_successful_delete)
    redirect_to colors_path
  end

  protected

  def default_breadcrumb
    if action_name == 'index'
      t('timelines.admin_menu.colors')
    else
      ActionController::Base.helpers.link_to(t('timelines.admin_menu.colors'), colors_path)
    end
  end

  def show_local_breadcrumb
    true
  end

  def require_admin_unless_readonly_api_request
    require_admin unless %w[index show].include? params[:action] and
                         api_request?
  end
end
