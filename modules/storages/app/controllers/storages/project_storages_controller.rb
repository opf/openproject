#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
  before_action :find_model_object, only: %i[open]
  before_action :find_project_by_project_id

  def open
    url = @object.open(current_user).match(
      on_success: ->(url) { url },
      on_failure: ->(error) { raise_error(error) }
    )

    modal_params = {
      project_storage_open_url: request.path,
      redirect_url: url
    }
    storage = @object.storage
    result = ::Storages::Peripherals::Registry
               .resolve("queries.#{storage.short_provider_type}.file_info")
               .call(storage:,
                     user: current_user,
                     file_id: @object.project_folder_id)

    redirect_to url if !@object.project_folder_automatic?
    result.match(
      on_success: ->(_) do
        respond_to do |format|
          format.turbo_stream do
            stream = OpTurbo::StreamComponent.new(
              action: :update,
              target: Storages::OpenProjectStorageModalComponent.dialog_body_id,
              template: Storages::OpenProjectStorageModalComponent::Body.new(:success).render_in(view_context)
            ).render_in(view_context)
            render turbo_stream: stream
          end
          format.html { redirect_to url }
        end
      end,
      on_failure: ->(result) do
        case result.code
        when :unauthorized
          respond_to do |format|
            format.turbo_stream { head :no_content }
            format.html do
              ensure_connection_url = oauth_clients_ensure_connection_url(
                oauth_client_id: storage.oauth_client.client_id,
                storage_id: storage.id,
                destination_url: request.url
              )
              redirect_to ensure_connection_url
            end
          end
        when :forbidden
          respond_to do |format|
            format.turbo_stream do
              head :no_content
            end
            format.html do
              flash[:modal] = {
                type: 'Storages::OpenProjectStorageModalComponent',
                parameters: modal_params.merge(state: :waiting)
              }
              redirect_to project_overview_path(project_id: @project.identifier)
            end
          end
        end
      end
    )
  end
end
