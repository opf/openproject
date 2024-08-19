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
  model_object Storages::ProjectStorage

  before_action :require_login
  before_action :find_model_object
  before_action :find_project_by_project_id
  before_action :render_403, unless: -> { User.current.allowed_in_project?(:view_file_links, @project) }
  no_authorization_required! :open

  # rubocop:disable Metrics/AbcSize
  def open
    if @object.project_folder_automatic?
      @storage = @object.storage
      # check if user "see" project_folder
      if @object.project_folder_id.present?
        ::Storages::Peripherals::Registry
          .resolve("#{@storage.short_provider_type}.queries.file_info")
          .call(storage: @storage, auth_strategy:, file_id: @object.project_folder_id)
          .match(
            on_success: user_can_read_project_folder,
            on_failure: user_can_not_read_project_folder
          )
      else
        respond_to do |format|
          format.turbo_stream { head :no_content }
          format.html do
            redirect_to_project_overview_with_modal
          end
        end
      end
    else
      redirect_to api_v3_project_storage_open
    end
  end

  # rubocop:enable Metrics/AbcSize

  private

  def auth_strategy
    Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken
      .strategy
      .with_user(current_user)
  end

  def user_can_read_project_folder
    ->(_) do
      respond_to do |format|
        format.turbo_stream do
          render(
            turbo_stream: OpTurbo::StreamComponent.new(
              action: :update,
              target: Storages::OpenProjectStorageModalComponent.dialog_body_id,
              template: Storages::OpenProjectStorageModalComponent::Body.new(:success).render_in(view_context)
            ).render_in(view_context)
          )
        end
        format.html { redirect_to api_v3_project_storage_open }
      end
    end
  end

  def user_can_not_read_project_folder
    ->(result) do
      respond_to do |format|
        format.turbo_stream { head :no_content }
        format.html do
          case result.code
          when :unauthorized
            redirect_to(
              oauth_clients_ensure_connection_url(
                oauth_client_id: @storage.oauth_client.client_id,
                storage_id: @storage.id,
                destination_url: request.url
              )
            )
          when :forbidden
            redirect_to_project_overview_with_modal
          end
        end
      end
    end
  end

  def redirect_to_project_overview_with_modal
    redirect_to(
      project_overview_path(project_id: @project.identifier),
      flash: {
        modal: {
          type: "Storages::OpenProjectStorageModalComponent",
          parameters: {
            project_storage_open_url: request.path,
            redirect_url: api_v3_project_storage_open,
            state: :waiting
          }
        }
      }
    )
  end

  def api_v3_project_storage_open
    ::API::V3::Utilities::PathHelper::ApiV3Path.project_storage_open(@object.id)
  end
end
