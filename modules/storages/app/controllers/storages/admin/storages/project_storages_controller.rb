# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

class Storages::Admin::Storages::ProjectStoragesController < ApplicationController
  include OpTurbo::ComponentStream
  include OpTurbo::DialogStreamHelper

  layout "admin"

  model_object Storages::Storage

  before_action :require_admin
  before_action :find_model_object

  before_action :storage_projects_query, only: :index
  before_action :initialize_project_storage, only: :new
  before_action :find_projects_to_activate_for_storage, only: :create

  menu_item :external_file_storages

  def index
    # Prepare data for project_folder_type column
    @project_folder_modes_per_project = Storages::ProjectStorage
      .where(storage_id: @storage.id)
      .pluck(:project_id, :project_folder_mode)
      .to_h
  end

  def new
    respond_with_dialog Storages::Admin::Storages::AddProjectsModalComponent.new(project_storage: @project_storage)
  end

  def create; end
  def destroy; end

  private

  def find_model_object(object_id = :storage_id)
    super
    @storage = @object
  end

  def find_projects_to_activate_for_storage
    if (project_ids = params.to_unsafe_h[:storages_project_storage][:project_ids]).present?
      @projects = Project.find(project_ids)
    else
      initialize_project_storage
      @project_storage.errors.add(:project_ids, :blank)
      component = Storages::Admin::Storages::AddProjectsFormModalComponent.new(project_storage: @project_storage)
      update_via_turbo_stream(component:, status: :bad_request)
      respond_with_turbo_streams
    end
  rescue ActiveRecord::RecordNotFound
    update_flash_message_via_turbo_stream message: t(:notice_project_not_found), full: true, dismiss_scheme: :hide,
                                          scheme: :danger
    update_project_list_via_turbo_stream

    respond_with_turbo_streams
  end

  def update_project_list_via_turbo_stream
    update_via_turbo_stream(
      component: Storages::ProjectStorages::Projects::TableComponent.new(query: storage_projects_query, params:)
    )
  end

  def storage_projects_query
    @storage_projects_query = ProjectQuery.new(name: "storage-projects-#{@storage.id}") do |query|
      query.where(:storages, "=", [@storage.id])
      query.select(:name)
      query.order("lft" => "asc")
    end
  end

  def initialize_project_storage
    @project_storage = ::Storages::ProjectStorages::SetAttributesService
        .new(user: current_user, model: ::Storages::ProjectStorage.new, contract_class: EmptyContract)
        .call(storage: @storage)
        .result
  end
end
