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

module WorkPackageTypes
  class TypesController < ApplicationController
    include PaginationHelper
    include OpTurbo::ComponentStream

    layout "admin"

    before_action :require_admin
    before_action :find_type, only: %i[move destroy drop duplicate menu deletion_dialog]

    current_menu_item do
      :types
    end

    def index
      @expanded_type_id = expanded_type_id
      @page_args = page_args
      @types = types_for_index
    end

    def type
      @type
    end

    def move
      type_params = params[:type]
      direction = type_params[:move_to] if type_params.is_a?(ActionController::Parameters)
      moved = direction.in?(%w[highest higher lower lowest]) && @type.update(move_to: direction)
      render_ordering_result(moved, error_key: :error_type_could_not_be_saved)
    end

    def destroy
      return refuse_deletion if @type.work_packages.exists?

      service_call = WorkPackageTypes::DeleteService.new(user: current_user, model: @type).call

      if service_call.success?
        flash[:notice] = I18n.t(:notice_successful_delete)
      else
        flash[:error] = service_call.errors.full_messages
      end

      redirect_to action: "index", status: :see_other
    end

    def deletion_dialog
      return refuse_deletion_via_turbo_stream if @type.work_packages.exists?

      respond_with_dialog Types::TypeDeletionDialogComponent.new(type: @type)
    end

    def duplicate
      service_call = WorkPackageTypes::DuplicateService.new(type: @type, user: current_user).call

      if service_call.success?
        flash[:notice] = t("types.index.duplicate_notice", name: @type.name)
      else
        flash[:error] = service_call.errors.full_messages
      end

      redirect_to types_path, status: :see_other
    end

    def drop
      render_ordering_result(move_after_anchor, error_key: :error_invalid_list_move_anchor)
    end

    def menu
      render Types::TypeActionsComponent.new(type: @type, page_args:, expanded_type_id:), layout: false
    end

    protected

    def page_args
      { page: page_param, per_page: per_page_param }
    end

    def expanded_type_id
      params[:expand].presence&.to_i
    end

    def ordering_component
      Types::GroupedListComponent.new(types: types_for_index,
                                      page_args:,
                                      expanded_type_id:)
    end

    def render_ordering_result(moved, error_key:)
      if moved
        render_success_flash_message_via_turbo_stream(message: I18n.t(:notice_successful_update))
        update_via_turbo_stream(component: ordering_component, method: :morph)
      else
        render_error_flash_message_via_turbo_stream(message: I18n.t(error_key))
      end
      respond_with_turbo_streams(status: moved ? :ok : :unprocessable_entity)
    end

    def valid_drop_request?
      params[:list_type] == ::Type.model_name.param_key &&
        (params[:list_id].nil? || params[:list_id] == "") &&
        params.key?(:prev_id)
    end

    def move_after_anchor
      return false unless valid_drop_request?

      predecessor = params[:prev_id]
      if predecessor.nil? || predecessor == ""
        move_to_page_start
      else
        @type.move_after_anchor(predecessor, scope: ::Type.all)
      end
    end

    def move_to_page_start
      current_page = ::Type.page(page_param).per_page(per_page_param)
      return false if current_page.empty?

      predecessor = ::Type.offset(current_page.offset - 1).pick(:id) if current_page.offset.positive?
      @type.move_after_anchor(predecessor, scope: ::Type.all)
    end

    def find_type
      @type = ::Type.find(params.expect(:id))
    end

    def types_for_index
      ::Type
        .includes(:color, :projects,
                  variants: %i[workflow custom_fields])
        .page(page_param)
        .per_page(per_page_param)
    end

    def refuse_deletion
      flash[:error] = destroy_error_message
      redirect_to action: "index", status: :see_other
    end

    def refuse_deletion_via_turbo_stream
      render_error_flash_message_via_turbo_stream(
        message: helpers.safe_join(destroy_error_message, helpers.tag.br)
      )

      respond_to_with_turbo_streams
    end

    def destroy_error_message
      error_message = [
        ApplicationController.helpers.sanitize(
          t(:"error_can_not_delete_type.explanation", url: belonging_wps_url(@type.id)),
          attributes: %w(href target)
        )
      ]

      if archived_projects.any?
        error_message << ApplicationController.helpers.sanitize(
          t(:error_can_not_delete_in_use_archived_work_packages,
            archived_projects_urls: helpers.archived_projects_urls_for(archived_projects)),
          attributes: %w(href target)
        )
      end

      error_message
    end

    def belonging_wps_url(type_id)
      work_packages_path query_props: { f: [{ n: "type", o: "=", v: [type_id] }] }.to_json
    end

    def archived_projects
      @archived_projects ||= @type.projects.archived
    end
  end
end
