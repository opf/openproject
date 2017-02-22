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

class VersionsController < ApplicationController
  menu_item :roadmap
  model_object Version
  before_action :find_model_object, except: [:index, :new, :create, :close_completed]
  before_action :find_project_from_association, except: [:index, :new, :create, :close_completed]
  before_action :find_project, only: [:index, :new, :create, :close_completed]
  before_action :authorize

  include VersionsHelper

  def index
    @types = @project.types.order('position')
    retrieve_selected_type_ids(@types, @types.select(&:is_in_roadmap?))
    @with_subprojects = params[:with_subprojects].nil? ? Setting.display_subprojects_work_packages? : (params[:with_subprojects].to_i == 1)
    project_ids = @with_subprojects ? @project.self_and_descendants.map(&:id) : [@project.id]

    @versions = @project.shared_versions || []
    @versions += @project.rolled_up_versions.visible if @with_subprojects
    @versions = @versions.uniq.sort
    @versions.reject! { |version| version.closed? || version.completed? } unless params[:completed]

    @issues_by_version = {}
    unless @selected_type_ids.empty?
      @versions.each do |version|
        issues = version.fixed_issues.visible.includes(:project, :status, :type, :priority)
                 .where(type_id: @selected_type_ids, project_id: project_ids)
                 .order("#{Project.table_name}.lft, #{::Type.table_name}.position, #{WorkPackage.table_name}.id")
        @issues_by_version[version] = issues
      end
    end
    @versions.reject! { |version| !project_ids.include?(version.project_id) && @issues_by_version[version].blank? }
  end

  def show
    @issues = @version.fixed_issues.visible.includes(:status, :type, :priority)
              .order("#{::Type.table_name}.position, #{WorkPackage.table_name}.id")
  end

  def new
    @version = @project.versions.build
    if permitted_params.version.present?
      attributes = permitted_params.version.dup
      attributes.delete('sharing') unless attributes.nil? || @version.allowed_sharings.include?(attributes['sharing'])
      @version.attributes = attributes
    end
  end

  def create
    # TODO: refactor with code above in #new
    @version = @project.versions.build
    if permitted_params.version.present?
      attributes = permitted_params.version.dup
      attributes.delete('sharing') unless attributes.nil? || @version.allowed_sharings.include?(attributes['sharing'])
      @version.attributes = attributes
    end

    if request.post?
      if @version.save
        flash[:notice] = l(:notice_successful_create)
        redirect_to controller: '/projects', action: 'settings', tab: 'versions', id: @project
      else
        render action: 'new'
      end
    end
  end

  def edit
  end

  def update
    if request.patch? && permitted_params.version
      attributes = permitted_params.version.dup
      attributes.delete('sharing') unless @version.allowed_sharings.include?(attributes['sharing'])
      @version.attributes = attributes
      if @version.save
        flash[:notice] = l(:notice_successful_update)
        redirect_back_or_default(settings_project_path(tab: 'versions', id: @project))
      else
        respond_to do |format|
          format.html do
            render action: 'edit'
          end
        end
      end
    end
  end

  def close_completed
    if request.put?
      @project.close_completed_versions
    end
    redirect_to controller: '/projects', action: 'settings', tab: 'versions', id: @project
  end

  def destroy
    if @version.fixed_issues.empty?
      @version.destroy
      redirect_to controller: '/projects', action: 'settings', tab: 'versions', id: @project
    else
      flash[:error] = l(:notice_unable_delete_version)
      redirect_to controller: '/projects', action: 'settings', tab: 'versions', id: @project
    end
  end

  def status_by
    respond_to do |format|
      format.html do render action: 'show' end
      format.js do render_status_by @version, params[:status_by] end
    end
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def retrieve_selected_type_ids(selectable_types, default_types = nil)
    if ids = params[:type_ids]
      @selected_type_ids = (ids.is_a? Array) ? ids.map { |id| id.to_i.to_s } : ids.split('/').map { |id| id.to_i.to_s }
    else
      @selected_type_ids = (default_types || selectable_types).map { |t| t.id.to_s }
    end
  end
end
