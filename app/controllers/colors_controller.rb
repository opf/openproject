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

class ColorsController < ApplicationController
  before_action :require_admin_unless_readonly_api_request
  authorization_checked! :index, :show, :new, :edit, :create, :update, :confirm_destroy, :destroy

  layout "admin"

  menu_item :colors

  def index
    @colors = Color.all.sort_by(&:name)
    respond_to do |format|
      format.html
    end
  end

  def show
    @color = Color.find(params[:id])
    respond_to do |_format|
    end
  end

  def new
    @color = Color.new
    respond_to do |format|
      format.html
    end
  end

  def edit
    @color = Color.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def create
    @color = Color.new(permitted_params.color)

    if @color.save
      flash[:notice] = I18n.t(:notice_successful_create)
      redirect_to colors_path
    else
      flash.now[:error] = I18n.t(:error_color_could_not_be_saved)
      render action: "new"
    end
  end

  def update
    @color = Color.find(params[:id])

    if @color.update(permitted_params.color)
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to colors_path
    else
      flash.now[:error] = I18n.t(:error_color_could_not_be_saved)
      render action: "edit"
    end
  end

  def confirm_destroy
    @color = Color.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def destroy
    @color = Color.find(params[:id])
    @color.destroy

    flash[:notice] = I18n.t(:notice_successful_delete)
    redirect_to colors_path
  end

  protected

  def show_local_breadcrumb
    false
  end

  def default_breadcrumb; end

  def require_admin_unless_readonly_api_request
    require_admin unless %w[index show].include? params[:action] and
                         api_request?
  end
end
