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
    include TypeVariantsFeature

    layout "admin"

    before_action :require_admin
    before_action :require_type_variants_feature, only: %i[drop duplicate menu]
    before_action :find_type, only: %i[move destroy drop duplicate menu]

    current_menu_item do
      :types
    end

    def index
      @expanded_type_id = params[:expand].presence&.to_i
      @types = types_for_index
    end

    def type
      @type
    end

    def new
      @type = Type.new(new_type_params)
      load_projects_and_types
    end

    def create
      service_call = WorkPackageTypes::CreateService.new(user: current_user).call(create_params)

      @type = service_call.result
      if service_call.success?
        redirect_to edit_type_details_path(type_id: @type.id), notice: t(:notice_successful_create), status: :see_other
      else
        render action: :new, status: :unprocessable_entity
      end
    end

    def move
      if @type.update(permitted_params.type_move)
        flash[:notice] = I18n.t(:notice_successful_update)
      else
        flash.now[:error] = I18n.t(:error_type_could_not_be_saved)
      end
      redirect_to types_path
    end

    def destroy
      if @type.work_packages.any?
        flash[:error] = destroy_error_message
      elsif @type.destroy
        flash[:notice] = I18n.t(:notice_successful_delete)
      else
        flash[:error] = @type.errors.full_messages
      end
      redirect_to action: "index", status: :see_other
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
      unless @type.update(params.permit(:position))
        render_error_flash_message_via_turbo_stream(message: @type.errors.full_messages.to_sentence)
      end

      update_via_turbo_stream(component: Types::GroupedListComponent.new(types: types_for_index))
      respond_to_with_turbo_streams
    end

    def menu
      render Types::TypeActionsComponent.new(type: @type), layout: false
    end

    protected

    def find_type
      @type = ::Type.find(params[:id])
    end

    def types_for_index
      ::Type
        .includes(:color, :projects,
                  variants: %i[own_workflows custom_fields])
        .page(page_param)
        .per_page(per_page_param)
    end

    def new_type_params
      return {} if params[:type].blank?

      permitted_type_params
    end

    # copy_workflow_from is a creation-time instruction rather than a type attribute,
    # so it is read straight off the request and only passed on when one was chosen.
    # TODO: Remove with type_variants feature flag
    def create_params
      copy_workflow_from = params.dig(:type, :copy_workflow_from)
      return permitted_type_params if copy_workflow_from.blank?

      permitted_type_params.merge(copy_workflow_from:)
    end

    def permitted_type_params
      # having to call #to_unsafe_h as a query hash the attribute_groups
      # parameters would otherwise still be an ActiveSupport::Parameter
      permitted_params.type.to_unsafe_h
    end

    def load_projects_and_types
      @types = ::Type.order(Arel.sql("position"))
      @projects = Project.all
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
