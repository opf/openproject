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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Storages::Admin::Storages::ProjectStoragesController < ApplicationController
  include OpTurbo::ComponentStream
  include OpTurbo::DialogStreamHelper
  include FlashMessagesOutputSafetyHelper
  include ApplicationComponentStreams
  include Storages::OAuthAccessGrantable

  layout "admin"

  model_object Storages::Storage

  before_action :require_admin
  before_action :find_model_object
  before_action :load_project_storage, only: %i(edit update destroy destroy_confirmation_dialog)

  before_action :storage_projects_query, only: :index
  before_action :ensure_storage_configured!, only: %i(new create)
  before_action :initialize_project_storage, only: :new
  before_action :find_projects_to_activate_for_storage, only: :create

  menu_item :external_file_storages

  def index; end

  def new
    respond_with_dialog(
      if storage_oauth_access_granted?(storage: @storage)
        ::Storages::Admin::Storages::ProjectsStorageModalComponent.new(
          project_storage: @project_storage, last_project_folders: {}
        )
      else
        ::Storages::Admin::Storages::OAuthAccessGrantNudgeModalComponent.new(storage: @storage)
      end
    )
  end

  def oauth_access_grant
    open_redirect_to_storage_authorization_with(
      callback_url: admin_settings_storage_project_storages_url(@storage),
      storage: @storage
    )
  end

  def create # rubocop:disable Metrics/AbcSize
    create_service = ::Storages::ProjectStorages::BulkCreateService
                         .new(user: current_user, projects: @projects, storage: @storage,
                              include_sub_projects: include_sub_projects?)
                         .call(params.to_unsafe_h[:storages_project_storage])

    create_service.on_success { update_project_list_via_turbo_stream(url_for_action: :index) }

    create_service.on_failure do
      project_storage = create_service.result
      project_storage.errors.merge!(create_service.errors)
      component = Storages::Admin::Storages::ProjectsStorageFormModalComponent.new(project_storage:)
      update_via_turbo_stream(component:, status: :bad_request)
    end

    respond_with_turbo_streams(status: create_service.success? ? :ok : :unprocessable_entity)
  end

  def edit
    last_project_folders = Storages::LastProjectFolder
                              .where(project_storage: @project_storage)
                              .pluck(:mode, :origin_folder_id)
                              .to_h

    respond_with_dialog Storages::Admin::Storages::ProjectsStorageModalComponent.new(
      project_storage: @project_storage, last_project_folders:
    )
  end

  def update
    update_service = ::Storages::ProjectStorages::UpdateService
                       .new(user: current_user, model: @project_storage)
                       .call(params.to_unsafe_h[:storages_project_storage].merge(storage: @storage))

    update_service.on_success { update_project_list_via_turbo_stream(url_for_action: :index) }

    update_service.on_failure do
      component = Storages::Admin::Storages::ProjectsStorageFormModalComponent.new(project_storage: @project_storage)
      update_via_turbo_stream(component:, status: :bad_request)
    end

    respond_with_turbo_streams(status: update_service.success? ? :ok : :unprocessable_entity)
  end

  def destroy_confirmation_dialog
    respond_with_dialog Storages::ProjectStorages::DestroyConfirmationDialogComponent.new(
      storage: @storage,
      project_storage: @project_storage
    )
  end

  def destroy
    delete_service = Storages::ProjectStorages::DeleteService
      .new(user: current_user, model: @project_storage)
      .call

    delete_service.on_success do
      update_flash_message_via_turbo_stream(
        message: I18n.t(:notice_successful_delete),
        full: true, dismiss_scheme: :hide, scheme: :success
      )
      update_project_list_via_turbo_stream(url_for_action: :index)
    end

    delete_service.on_failure do |failure|
      error = failure.errors.map(&:message).to_sentence
      render_error_flash_message_via_turbo_stream(
        message: I18n.t("project_storages.remove_project.deletion_failure_flash", error:),
        full: true, dismiss_scheme: :hide
      )
    end

    respond_to_with_turbo_streams(status: delete_service.success? ? :ok : :unprocessable_entity)
  end

  private

  def load_project_storage
    @project_storage = Storages::ProjectStorage.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    update_flash_message_via_turbo_stream(
      message: t(:notice_file_not_found), full: true, dismiss_scheme: :hide, scheme: :danger
    )
    update_project_list_via_turbo_stream

    respond_with_turbo_streams
  end

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
      component = Storages::Admin::Storages::ProjectsStorageFormModalComponent.new(project_storage: @project_storage)
      update_via_turbo_stream(component:, status: :bad_request)
      respond_with_turbo_streams
    end
  rescue ActiveRecord::RecordNotFound
    update_flash_message_via_turbo_stream message: t(:notice_project_not_found), full: true, dismiss_scheme: :hide,
                                          scheme: :danger
    update_project_list_via_turbo_stream

    respond_with_turbo_streams
  end

  def update_project_list_via_turbo_stream(url_for_action: action_name)
    update_via_turbo_stream(
      component: Storages::ProjectStorages::Projects::TableComponent.new(
        query: storage_projects_query,
        storage: @storage,
        params: { url_for_action: }
      )
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

  def include_sub_projects?
    ActiveRecord::Type::Boolean.new.cast(params.to_unsafe_h[:storages_project_storage][:include_sub_projects])
  end

  def ensure_storage_configured!
    return if @storage.configured?

    update_flash_message_via_turbo_stream(
      message: I18n.t("storages.enabled_in_projects.setup_incomplete_description"),
      full: true,
      dismiss_scheme: :hide,
      scheme: :danger
    )
    respond_with_turbo_streams
    false
  end
end
