# -- copyright
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
# ++

class Projects::QueriesController < ApplicationController
  include Projects::QueryLoading
  include OpTurbo::ComponentStream
  include OpTurbo::DialogStreamHelper

  # No need for a more specific authorization check. That is carried out in the contracts.
  no_authorization_required! :show, :new, :create, :rename, :update, :toggle_public, :destroy, :destroy_confirmation_modal,
                             :configure_view_modal
  before_action :require_login, except: %i[configure_view_modal]
  before_action :find_query, only: %i[show rename update destroy toggle_public destroy_confirmation_modal]
  before_action :build_query_or_deny_access, only: %i[new create configure_view_modal]

  current_menu_item [:new, :rename, :create, :update] do
    :projects
  end

  def show
    redirect_to projects_path(query_id: @query.id)
  end

  def new
    respond_to do |format|
      format.html do
        render template: "/projects/index",
               layout: "global",
               locals: { query: @query, state: :edit }
      end
      format.turbo_stream do
        replace_via_turbo_stream(
          component: Projects::IndexPageHeaderComponent.new(query: @query, current_user:, state: :edit, params:)
        )

        render turbo_stream: turbo_streams
      end
    end
  end

  def rename
    respond_to do |format|
      format.html do
        render template: "/projects/index",
               layout: "global",
               locals: { query: @query, state: :rename }
      end
      format.turbo_stream do
        replace_via_turbo_stream(
          component: Projects::IndexPageHeaderComponent.new(query: @query, current_user:, state: :rename, params:)
        )

        render turbo_stream: turbo_streams
      end
    end
  end

  def create
    call = Queries::Projects::ProjectQueries::CreateService
             .new(from: @query, user: current_user)
             .call(permitted_query_params)

    render_result(call, success_i18n_key: "lists.create.success", error_i18n_key: "lists.create.failure")
  end

  def update
    call = Queries::Projects::ProjectQueries::UpdateService
             .new(user: current_user, model: @query)
             .call(permitted_query_params)

    render_result(call, success_i18n_key: "lists.update.success", error_i18n_key: "lists.update.failure")
  end

  def toggle_public # rubocop:disable Metrics/AbcSize
    to_be_public = ActiveRecord::Type::Boolean.new.cast(params["value"])
    i18n_key = to_be_public ? "lists.publish" : "lists.unpublish"

    call = Queries::Projects::ProjectQueries::PublishService
             .new(user: current_user, model: @query)
             .call(public: to_be_public)

    respond_to do |format|
      format.turbo_stream do
        # Load shares and replace the modal
        strategy = SharingStrategies::ProjectQueryStrategy.new(@query, user: current_user, query_params: {})
        replace_via_turbo_stream(component: Shares::ModalBodyComponent.new(strategy:, errors: []))
        render turbo_stream: turbo_streams
      end

      format.html do
        render_result(call, success_i18n_key: "#{i18n_key}.success", error_i18n_key: "#{i18n_key}.failure")
      end
    end
  end

  def destroy
    Queries::Projects::ProjectQueries::DeleteService.new(user: current_user, model: @query)
                                                    .call

    redirect_to projects_path
  end

  def destroy_confirmation_modal
    respond_with_dialog Projects::DeleteListModalComponent.new(query: @query)
  end

  def configure_view_modal
    respond_with_dialog Projects::ConfigureViewModalComponent.new(query: @query)
  end

  private

  def render_result(service_call, success_i18n_key:, error_i18n_key:) # rubocop:disable Metrics/AbcSize
    modified_query = service_call.result

    if service_call.success?
      flash[:notice] = I18n.t(success_i18n_key)

      redirect_to modified_query.visible? ? projects_path(query_id: modified_query.id) : projects_path
    else
      flash[:error] = I18n.t(error_i18n_key, errors: service_call.errors.full_messages.join("\n"))

      render template: "/projects/index",
             layout: "global",
             locals: { query: modified_query, state: :edit }
    end
  end

  def find_query
    @query = ProjectQuery.visible(current_user).find(params[:id])
  end
end
