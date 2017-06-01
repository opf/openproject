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

class StatusesController < ApplicationController
  include PaginationHelper

  layout 'admin'

  before_action :require_admin

  verify method: :get, only: :index, render: { nothing: true, status: :method_not_allowed }
  def index
    @statuses = Status.page(params[:page])
                .per_page(per_page_param)

    render action: 'index', layout: false if request.xhr?
  end

  verify method: :get, only: :new, render: { nothing: true, status: :method_not_allowed }
  def new
    @status = Status.new
  end

  verify method: :post, only: :create, render: { nothing: true, status: :method_not_allowed }
  def create
    @status = Status.new(permitted_params.status)
    if @status.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to action: 'index'
    else
      render action: 'new'
    end
  end

  verify method: :get, only: :edit, render: { nothing: true, status: :method_not_allowed }
  def edit
    @status = Status.find(params[:id])
  end

  verify method: :patch, only: :update, render: { nothing: true, status: :method_not_allowed }
  def update
    @status = Status.find(params[:id])
    if @status.update_attributes(permitted_params.status)
      flash[:notice] = l(:notice_successful_update)
      redirect_to action: 'index'
    else
      render action: 'edit'
    end
  end

  verify method: :delete, only: :destroy, render: { nothing: true, status: :method_not_allowed }
  def destroy
    status = Status.find(params[:id])
    if status.is_default?
      flash[:error] = l(:error_unable_delete_default_status)
    else
      status.destroy
      flash[:notice] = l(:notice_successful_delete)
    end
    redirect_to action: 'index'
  rescue
    flash[:error] = l(:error_unable_delete_status)
    redirect_to action: 'index'
  end

  verify method: :post, only: :update_work_package_done_ratio,
         render: { nothing: true, status: 405 }
  def update_work_package_done_ratio
    if Status.update_work_package_done_ratios
      flash[:notice] = l(:notice_work_package_done_ratios_updated)
    else
      flash[:error] =  l(:error_work_package_done_ratios_not_updated)
    end
    redirect_to action: 'index'
  end

  protected

  def default_breadcrumb
    if action_name == 'index'
      t(:label_work_package_status_plural)
    else
      ActionController::Base.helpers.link_to(t(:label_work_package_status_plural), statuses_path)
    end
  end

  def show_local_breadcrumb
    true
  end
end
