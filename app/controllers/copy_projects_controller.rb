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

class CopyProjectsController < ApplicationController
  helper :timelines

  before_filter :disable_api
  before_filter :find_project
  before_filter :authorize, :only => [ :copy, :copy_project ]

  def copy
    @source_project = @project
    UserMailer.with_deliveries(params[:notifications] == '1') do
      @project = Project.new
      @project.safe_attributes = params[:project]
      @project.enabled_module_names = params[:enabled_modules]
      if validate_parent_id && @project.copy_associations(@source_project, :only => params[:only])
        @project.set_allowed_parent!(params[:project]['parent_id']) if params[:project].has_key?('parent_id')
        flash[:notice] = l(:notice_successful_create)
        redirect_to :controller => '/projects', :action => 'settings', :id => @project
      elsif !@project.valid?
        # Project was created
        # But some objects were not copied due to validation failures
        # (eg. issues from disabled types)
        # TODO: inform about that
        redirect_to :back
      end
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to :back
  end

  def copy_project
    from = params[:coming_from].to_sym || :settings
    @issue_custom_fields = WorkPackageCustomField.find(:all, :order => "#{CustomField.table_name}.position")
    @types = Type.all
    @root_projects = Project.find(:all,
                                  :conditions => "parent_id IS NULL AND status = #{Project::STATUS_ACTIVE}",
                                  :order => 'name')
    @copy_project = Project.copy_attributes(@project)
    if @copy_project
      @copy_project.identifier = Project.next_identifier if Setting.sequential_project_identifiers?
    else
      redirect_to :back
    end
    render :action => :"copy_from_#{from}"
  rescue ActiveRecord::RecordNotFound
    redirect_to :back
  end

  protected

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