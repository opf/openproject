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

class ProjectsController < ApplicationController
  menu_item :overview
  menu_item :roadmap, only: :roadmap
  menu_item :settings, only: :settings

  helper :timelines

  before_filter :disable_api
  before_filter :find_project, except: [:index, :level_list, :new, :create]
  before_filter :authorize, only: [:show, :settings, :edit, :update, :modules, :types]
  before_filter :authorize_global, only: [:new, :create]
  before_filter :require_admin, only: [:archive, :unarchive, :destroy, :destroy_info]
  before_filter :jump_to_project_menu_item, only: :show
  before_filter :load_project_settings, only: :settings
  before_filter :determine_base

  accept_key_auth :index, :level_list, :show, :create, :update, :destroy

  after_filter only: [:create, :edit, :update, :archive, :unarchive, :destroy] do |controller|
    if controller.request.post?
      controller.send :expire_action, controller: '/welcome', action: 'robots.txt'
    end
  end

  include SortHelper
  include CustomFieldsHelper
  include QueriesHelper
  include RepositoriesHelper
  include ProjectsHelper

  # Lists visible projects
  def index
    respond_to do |format|
      format.html {
        @projects = Project.visible.find(:all, order: 'lft')
      }
      format.atom {
        projects = Project.visible.find(:all, order: 'created_on DESC',
                                              limit: Setting.feeds_limit.to_i)
        render_feed(projects, title: "#{Setting.app_title}: #{l(:label_project_latest)}")
      }
    end
  end

  def new
    @issue_custom_fields = WorkPackageCustomField.find(:all, order: "#{CustomField.table_name}.position")
    @types = Type.all
    @project = Project.new
    @project.parent = Project.find(params[:parent_id]) if params[:parent_id]
    @project.safe_attributes = params[:project]
  end

  def create
    @issue_custom_fields = WorkPackageCustomField.find(:all, order: "#{CustomField.table_name}.position")
    @types = Type.all
    @project = Project.new
    @project.safe_attributes = params[:project]

    if validate_parent_id && @project.save
      @project.set_allowed_parent!(params[:project]['parent_id']) if params[:project].has_key?('parent_id')
      add_current_user_to_project_if_not_admin(@project)
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_to controller: '/projects', action: 'settings', id: @project
        }
      end
    else
      respond_to do |format|
        format.html { render action: 'new' }
      end
    end
  end

  # Show @project
  def show
    @users_by_role = @project.users_by_role
    @subprojects = @project.children.visible.all
    @news = @project.news.find(:all, limit: 5, include: [:author, :project], order: "#{News.table_name}.created_on DESC")
    @types = @project.rolled_up_types

    cond = @project.project_condition(Setting.display_subprojects_work_packages?)

    @open_issues_by_type = WorkPackage.visible.count(group: :type,
                                                     include: [:project, :status, :type],
                                                     conditions: ["(#{cond}) AND #{Status.table_name}.is_closed=?", false])
    @total_issues_by_type = WorkPackage.visible.count(group: :type,
                                                      include: [:project, :status, :type],
                                                      conditions: cond)

    respond_to do |format|
      format.html
    end
  end

  def settings
  end

  def edit
  end

  def update
    @project.safe_attributes = params[:project]
    if validate_parent_id && @project.save
      @project.set_allowed_parent!(params[:project]['parent_id']) if params[:project].has_key?('parent_id')
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_to action: 'settings', id: @project
        }
      end
    else
      respond_to do |format|
        format.html {
          load_project_settings
          render action: 'settings'
        }
      end
    end
  end

  def types
    flash[:notice] = []

    unless params.has_key? :project
      params[:project] = { 'type_ids' => [Type.standard_type.id] }
      flash[:notice] << l(:notice_automatic_set_of_standard_type)
    end

    params[:project].assert_valid_keys('type_ids')

    selected_type_ids = params[:project][:type_ids].map(&:to_i)

    if types_missing?(selected_type_ids)
      flash.delete :notice
      flash[:error] = I18n.t(:error_types_in_use_by_work_packages,
                             types: missing_types(selected_type_ids).map(&:name).join(', '))
    elsif @project.update_attributes(params[:project])
      flash[:notice] << l('notice_successful_update')
    else
      flash[:error] = l('timelines.cannot_update_planning_element_types')
    end
    redirect_to action: 'settings', tab: 'types'
  end

  def modules
    @project.enabled_module_names = params[:project][:enabled_module_names]
    flash[:notice] = l(:notice_successful_update)
    redirect_to action: 'settings', id: @project, tab: 'modules'
  end

  def archive
    flash[:error] = l(:error_can_not_archive_project) unless @project.archive
    redirect_to(url_for(controller: '/admin', action: 'projects', status: params[:status]))
  end

  def unarchive
    @project.unarchive if !@project.active?
    redirect_to(url_for(controller: '/admin', action: 'projects', status: params[:status]))
  end

  # Delete @project
  def destroy
    @project_to_destroy = @project

    if params[:confirm]
      @project_to_destroy.destroy
      respond_to do |format|
        format.html { redirect_to controller: '/admin', action: 'projects' }
      end
    else
      flash[:error] = l(:notice_project_not_deleted)
      redirect_to confirm_destroy_project_path(@project)
      return
    end

    hide_project_in_layout
  end

  def destroy_info
    @project_to_destroy = @project

    hide_project_in_layout
  end

  private

  def find_optional_project
    return true unless params[:id]
    @project = Project.find(params[:id])
    authorize
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def jump_to_project_menu_item
    if params[:jump]
      # try to redirect to the requested menu item
      redirect_to_project_menu_item(@project, params[:jump]) && return
    end
  end

  def load_project_settings
    @issue_custom_fields = WorkPackageCustomField.find(:all, order: "#{CustomField.table_name}.position")
    @category ||= Category.new
    @member ||= @project.members.new
    @types = Type.all
    @repository ||= @project.repository
    @wiki ||= @project.wiki
  end

  def hide_project_in_layout
    @project = nil
  end

  def add_current_user_to_project_if_not_admin(project)
    unless User.current.admin?
      r = Role.givable.find_by_id(Setting.new_project_user_role_id.to_i) || Role.givable.first
      m = Member.new do |member|
        member.user = User.current
        member.role_ids = [r].map(&:id) # member.roles = [r] fails, this works
      end
      project.members << m
    end
  end

  protected

  def determine_base
    if params[:project_type_id]
      @base = ProjectType.find(params[:project_type_id]).projects
    else
      @base = Project
    end
  end

  def types_missing?(selected_type_ids)
    !missing_types(selected_type_ids).empty?
  end

  def missing_types(selected_type_ids)
    types_used_by_work_packages.select { |t| !selected_type_ids.include?(t.id) }
  end

  def types_used_by_work_packages
    @types_used_by_work_packages ||= Type.find_all_by_id(WorkPackage.where(project_id: @project.id)
                                                                    .select(:type_id)
                                                                    .uniq)
  end

  # Validates parent_id param according to user's permissions
  # TODO: move it to Project model in a validation that depends on User.current
  def validate_parent_id
    return true if User.current.admin?
    parent_id = params[:project] && params[:project][:parent_id]
    if parent_id || @project.new_record?
      parent = parent_id.blank? ? nil : Project.find_by_id(parent_id.to_i)
      unless @project.allowed_parents.include?(parent)
        @project.errors.add :parent_id, :invalid
        return false
      end
    end
    true
  end
end
