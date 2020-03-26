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

class StatusesController < ApplicationController
  include PaginationHelper

  layout 'admin'

  before_action :require_admin

  def index
    @statuses = Status.page(page_param)
                .per_page(per_page_param)

    render action: 'index', layout: false if request.xhr?
  end

  def new
    @status = Status.new
  end

  def create
    @status = Status.new(permitted_params.status)
    if @status.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to action: 'index'
    else
      render action: 'new'
    end
  end

  def edit
    @status = Status.find(params[:id])
  end

  def update
    @status = Status.find(params[:id])
    if @status.update(permitted_params.status)
      flash[:notice] = l(:notice_successful_update)
      redirect_to action: 'index'
    else
      render action: 'edit'
    end
  end

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
