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

class CopyProjectsController < ApplicationController
  before_action :find_project
  before_action :authorize

  def copy
    @copy_project = Project.new
    call = project_copy(@copy_project)

    if call.success?
      enqueue_copy_job

      copy_started_notice
      redirect_to origin
    else
      @errors = call.errors
      render action: copy_action
    end
  end

  def copy_project
    @copy_project = Project.copy_attributes(@project)

    if @copy_project
      project_copy(@copy_project, EmptyContract)

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

  def project_copy(nucleous, contract = Projects::CreateContract)
    Projects::SetAttributesService
      .new(user: current_user,
           model: nucleous,
           contract_class: contract)
      .call(params[:project] ? permitted_params.project : {})
  end

  def origin
    params[:coming_from] == 'admin' ? projects_path : settings_generic_project_path(@project.id)
  end

  def enqueue_copy_job
    CopyProjectJob.perform_later(user_id: User.current.id,
                                 source_project_id: @project.id,
                                 target_project_params: target_project_params,
                                 associations_to_copy: params[:only],
                                 send_mails: params[:notifications] == '1')
  end

  ##
  # Returns the target project params for
  # the project to be copied. Stringifies id keys of custom field values
  # due to serialization
  def target_project_params
    @copy_project
      .attributes
      .compact
      .with_indifferent_access
      .merge(custom_field_values: @copy_project.custom_value_attributes.transform_keys(&:to_s))
  end

  def copy_started_notice
    flash[:notice] = I18n.t('copy_project.started',
                            source_project_name: @project.name,
                            target_project_name: permitted_params.project[:name])
  end
end
