#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

class CopyProjectsController < ApplicationController
  before_action :disable_api
  before_action :find_project
  before_action :authorize

  def copy
    @copy_project = project_copy

    if @copy_project.valid?
      enqueue_copy_job

      flash[:notice] = I18n.t('copy_project.started',
                              source_project_name: @project.name,
                              target_project_name: permitted_params.project[:name])
      redirect_to origin
    else
      render action: copy_action
    end
  end

  def copy_project
    @copy_project = Project.copy_attributes(@project)
    if @copy_project
      @copy_project.identifier = Project.next_identifier if Setting.sequential_project_identifiers?

      render action: copy_action
    else
      redirect_to :back
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to :back
  end

  private

  def copy_action
    from = (%w(admin settings).include?(params[:coming_from]) ? params[:coming_from] : 'settings')

    "copy_from_#{from}"
  end

  def project_copy
    copy_project = Project.new
    copy_project.attributes = permitted_params.project

    # cannot use set_allowed_parent! as it requires a persisted project
    if copy_project.allowed_parent?(params['project']['parent_id'])
      copy_project.parent_id = params['project']['parent_id']
    end

    copy_project
  end

  def origin
    params[:coming_from] == 'admin' ? projects_path : settings_project_path(@project.id)
  end

  def enqueue_copy_job
    copy_project_job = CopyProjectJob.new(user_id: User.current.id,
                                          source_project_id: @project.id,
                                          target_project_params: target_project_params,
                                          associations_to_copy: params[:only],
                                          send_mails: params[:notifications] == '1')

    Delayed::Job.enqueue copy_project_job, priority: ::ApplicationJob.priority_number(:low)
  end

  def target_project_params
    @copy_project
      .attributes
      .compact
      .with_indifferent_access
      .merge(custom_field_values: @copy_project.custom_value_attributes)
  end
end
