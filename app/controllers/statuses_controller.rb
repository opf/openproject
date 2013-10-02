#-- encoding: UTF-8
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

class StatusesController < ApplicationController
  include PaginationHelper

  layout 'admin'

  before_filter :require_admin

  verify :method => :post, :only => [ :destroy, :create, :update, :move, :update_work_package_done_ratio ],
         :redirect_to => { :action => :index }

  def index
    @statuses = Status.order('position')
                                 .page(params[:page])
                                 .per_page(per_page_param)

    render :action => "index", :layout => false if request.xhr?
  end

  def new
    @status = Status.new
  end

  def create
    @status = Status.new(params[:status])
    if @status.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end

  def edit
    @status = Status.find(params[:id])
  end

  def update
    @status = Status.find(params[:id])
    if @status.update_attributes(params[:status])
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'index'
    else
      render :action => 'edit'
    end
  end

  def destroy
    Status.find(params[:id]).destroy
    redirect_to :action => 'index'
  rescue
    flash[:error] = l(:error_unable_delete_status)
    redirect_to :action => 'index'
  end

  def update_work_package_done_ratio
    if Status.update_work_package_done_ratios
      flash[:notice] = l(:notice_work_package_done_ratios_updated)
    else
      flash[:error] =  l(:error_work_package_done_ratios_not_updated)
    end
    redirect_to :action => 'index'
  end
end
