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

class CopyProjectsController < ApplicationController
  helper :timelines

  before_filter :disable_api
  before_filter :find_project
  before_filter :authorize, only: [:copy, :copy_project]
  before_filter :prepare_for_copy_project, only: [:copy, :copy_project]

  def copy
    target_project_name = params[:project][:name]
    @copy_project = Project.new
    @copy_project.safe_attributes = params[:project]
    if @copy_project.valid?
      modules = params[:project][:enabled_module_names] || params[:enabled_modules]
      copy_project_job = CopyProjectJob.new(User.current.id,
                                            @project.id,
                                            params[:project],
                                            modules,
                                            params[:only],
                                            params[:notifications] == '1')

      Delayed::Job.enqueue copy_project_job
      flash[:notice] = I18n.t('copy_project.started',
                              source_project_name: @project.name,
                              target_project_name: target_project_name)
      redirect_to :back
    else
      from = (['admin', 'settings'].include?(params[:coming_from]) ? params[:coming_from] : 'settings')
      render action: "copy_from_#{from}"
    end
  end

  def copy_project
    from = (['admin', 'settings'].include?(params[:coming_from]) ? params[:coming_from] : 'settings')
    @copy_project = Project.copy_attributes(@project)
    if @copy_project
      @copy_project.identifier = Project.next_identifier if Setting.sequential_project_identifiers?
      render action: "copy_from_#{from}"
    else
      redirect_to :back
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to :back
  end

  private

  def prepare_for_copy_project
    @issue_custom_fields = WorkPackageCustomField.find(:all, order: "#{CustomField.table_name}.position")
    @types = Type.all
    @root_projects = Project.find(:all,
                                  conditions: "parent_id IS NULL AND status = #{Project::STATUS_ACTIVE}",
                                  order: 'name')
  end
end
