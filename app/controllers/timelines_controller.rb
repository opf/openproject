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

class TimelinesController < ApplicationController
  helper :timelines

  before_action :disable_api
  before_action :find_project_by_project_id
  before_action :authorize

  def index
    @timeline = @project.timelines.first
    if @timeline.nil?
      redirect_to new_project_timeline_path(@project)
    else
      redirect_to project_timeline_path(@project, @timeline)
    end
  end

  def show
    @visible_timelines = @project.timelines

    @timeline = @project.timelines.find(params[:id])
  end

  def new
    @timeline = @project.timelines.build
  end

  def create
    remove_blank_options

    @timeline = @project.timelines.build(permitted_params.timeline)

    if @timeline.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to project_timeline_path(@project, @timeline)
    else
      render action: 'new'
    end
  end

  def edit
    @timeline = @project.timelines.find(params[:id])
  end

  def update
    @timeline = @project.timelines.find(params[:id])

    if @timeline.update_attributes(permitted_params.timeline)
      flash[:notice] = l(:notice_successful_update)
      redirect_to project_timeline_path(@project, @timeline)
    else
      render action: 'edit'
    end
  end

  def confirm_destroy
    @timeline = @project.timelines.find(params[:id])
  end

  def destroy
    @timeline = @project.timelines.find(params[:id])
    @timeline.destroy

    flash[:notice] = l(:notice_successful_delete)
    redirect_to project_timelines_path @project
  end

  protected

  def default_breadcrumb
    l('timelines.project_menu.timelines')
  end

  def remove_blank_options
    options = permitted_params.timeline[:options] || {}

    options.each do |k, v|
      options[k] = v.reject(&:blank?) if v.is_a? Array
    end

    permitted_params.timeline[:options] = options
  end
end
