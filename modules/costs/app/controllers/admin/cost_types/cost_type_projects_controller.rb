# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Admin::CostTypes::CostTypeProjectsController < ApplicationController
  include OpTurbo::ComponentStream
  include FlashMessagesOutputSafetyHelper

  layout "admin"

  before_action :require_admin
  before_action :find_cost_type

  before_action :available_cost_types_projects_query, only: %i[index destroy]
  before_action :initialize_cost_type_project, only: :new
  before_action :find_projects_to_activate_for_cost_type, only: :create
  before_action :find_cost_type_project_to_destroy, only: :destroy

  menu_item :cost_types

  def index; end

  def new
    respond_with_dialog Admin::CostTypes::CostTypeProjects::NewCostTypeProjectsModalComponent.new(
      cost_type_project_mapping: @cost_type_project,
      cost_type: @cost_type
    )
  end

  def create
    create_service = ::CostTypes::CostTypeProjects::BulkCreateService
                       .new(user: current_user, projects: @projects, model: @cost_type,
                            include_sub_projects: include_sub_projects?)
                       .call

    create_service.on_success { render_project_list(url_for_action: :index) }

    create_service.on_failure do
      render_error_flash_message_via_turbo_stream(
        message: join_flash_messages(create_service.errors)
      )
    end

    respond_to_with_turbo_streams(status: create_service.success? ? :ok : :unprocessable_entity)
  end

  def destroy
    delete_service = ::CostTypes::CostTypeProjects::DeleteService
                       .new(user: current_user, model: @cost_type_project)
                       .call

    delete_service.on_success { render_project_list(url_for_action: :index) }

    delete_service.on_failure do
      render_error_flash_message_via_turbo_stream(
        message: join_flash_messages(delete_service.errors.full_messages)
      )
    end

    respond_to_with_turbo_streams(status: delete_service.success? ? :ok : :unprocessable_entity)
  end

  private

  def render_project_list(url_for_action: action_name)
    update_via_turbo_stream(
      component: Admin::CostTypes::CostTypeProjects::TableComponent.new(
        query: available_cost_types_projects_query,
        params: params.merge({ cost_type: @cost_type, url_for_action: })
      )
    )
  end

  def find_cost_type
    @cost_type = CostType.find(params.expect(:cost_type_id))
  end

  def find_projects_to_activate_for_cost_type
    if (project_ids = params.to_unsafe_h.dig(:cost_types_project, :project_ids)).present?
      @projects = Project.visible.find(project_ids)
    else
      initialize_cost_type_project
      @cost_type_project.errors.add(:project_ids, :blank)
      update_via_turbo_stream(
        component: Admin::CostTypes::CostTypeProjects::NewCostTypeProjectsFormModalComponent.new(
          cost_type_project_mapping: @cost_type_project,
          cost_type: @cost_type
        ),
        status: :bad_request
      )
      respond_with_turbo_streams
    end
  rescue ActiveRecord::RecordNotFound
    respond_with_project_not_found_turbo_streams
  end

  def find_cost_type_project_to_destroy
    project_id = params.expect(cost_types_project: [:project_id]).fetch(:project_id)
    @cost_type_project = CostTypesProject.find_by!(cost_type: @cost_type, project: project_id)
  rescue ActiveRecord::RecordNotFound
    respond_with_project_not_found_turbo_streams
  end

  def available_cost_types_projects_query
    @available_cost_types_projects_query = ProjectQuery.new(
      name: "cost-types-projects-#{@cost_type.id}"
    ) do |query|
      query.where(:available_cost_types_projects, "=", [@cost_type.id])
      query.select(:name)
      query.order("lft" => "asc")
    end
  end

  def initialize_cost_type_project
    @cost_type_project = ::CostTypes::CostTypeProjects::SetAttributesService
                           .new(user: current_user, model: CostTypesProject.new, contract_class: EmptyContract)
                           .call(cost_type: @cost_type)
                           .result
  end

  def respond_with_project_not_found_turbo_streams
    render_error_flash_message_via_turbo_stream message: t(:notice_project_not_found)
    render_project_list(url_for_action: :index)

    respond_with_turbo_streams
  end

  def include_sub_projects?
    ActiveRecord::Type::Boolean.new.cast(params.to_unsafe_h.dig(:cost_types_project, :include_sub_projects))
  end
end
