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

class Storages::ProjectStoragesController < ApplicationController
  using Storages::Peripherals::ServiceResultRefinements

  menu_item :overview

  before_action :require_login
  before_action :find_project_by_project_id
  before_action :find_project_storage
  before_action :render_403, unless: -> { User.current.allowed_in_project?(:view_file_links, @project) }
  no_authorization_required! :open

  before_action :ensure_remote_identity, only: :open
  before_action :ensure_folder_created, only: :open
  before_action :ensure_folder_permissions, only: :open

  def open
    @project_storage.open(current_user).match(
      on_success: ->(url) { redirect_to url, allow_other_host: true },
      on_failure: ->(error) { show_error(error.code.to_s) }
    )
  end

  private

  def find_project_storage
    @project_storage = @project.project_storages.find(params[:id])
  end

  def ensure_remote_identity
    case Storages::Adapters::Authentication.authorization_state(storage:, user: current_user)
    when :not_connected
      redirect_to ensure_connection_url
    when :error, :failed_authorization
      show_error(I18n.t("project_storages.open.remote_identity_error"))
    else
      true
    end
  end

  def ensure_folder_created
    return unless @project_storage.project_folder_automatic?
    return if @project_storage.project_folder_id.present?

    folder_create_service.call(storage:, project_storages_scope: project_storage_scope).on_failure do |result|
      return show_error(result.errors.full_messages)
    end

    @project_storage.reload
  end

  def ensure_folder_permissions
    return unless @project_storage.project_folder_automatic?

    result = test_folder_access
    return if result.success? || result.failure.code != :forbidden

    # Note: The time this operation takes may still scale with the number of users.
    # If this becomes a problem, we will have to update downstream code to allow changing permissions for a few users instead of
    # requiring to always set all permissions.
    folder_permissions_service.call(storage:, project_storages_scope: project_storage_scope).on_failure do |r|
      return show_error(r.errors.full_messages)
    end
  end

  def ensure_connection_url
    oauth_clients_ensure_connection_url(
      oauth_client_id: storage.oauth_client.client_id,
      integration_id: storage.id,
      destination_url: request.url
    )
  end

  def folder_create_service
    Storages::Adapters::Registry.resolve("#{storage}.services.upkeep_managed_folders")
  end

  def folder_permissions_service
    Storages::Adapters::Registry.resolve("#{storage}.services.upkeep_managed_folder_permissions")
  end

  def file_info
    Storages::Adapters::Registry.resolve("#{storage}.queries.file_info")
  end

  def user_bound
    Storages::Adapters::Registry.resolve("#{storage}.authentication.user_bound")
  end

  def storage
    @project_storage.storage
  end

  def project_storage_scope
    @project.project_storages.where(id: @project_storage.id)
  end

  def test_folder_access
    Storages::Adapters::Input::FileInfo.build(file_id: @project_storage.project_folder_id).bind do |input_data|
      file_info.call(storage:, auth_strategy: user_bound.call(current_user, storage), input_data:)
    end
  end

  def show_error(message)
    flash[:error] = Array(message) + [I18n.t("project_storages.open.contact_admin")]
    redirect_back_or_to(project_path(id: @project_storage.project_id))
  end
end
