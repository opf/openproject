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

module Admin::Settings
  class ProjectPhaseDefinitionsController < ::Admin::SettingsController
    include FlashMessagesOutputSafetyHelper
    include OpTurbo::ComponentStream
    include Projects::PhaseDefinitionHelper

    menu_item :project_phase_definitions_settings

    before_action :require_enterprise_token, except: %i[index]

    before_action :find_definitions, only: %i[index]
    before_action :find_definition, only: %i[edit update destroy move]

    def index; end

    def new
      @definition = Project::PhaseDefinition.new

      render :form
    end

    def edit
      render :form
    end

    def create
      @definition = Project::PhaseDefinition.new(definition_params)

      if @definition.save
        flash[:notice] = I18n.t(:notice_successful_create)
        redirect_to action: :index, status: :see_other
      else
        render :form, status: :unprocessable_entity
      end
    end

    def update
      if @definition.update(definition_params)
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to action: :index, status: :see_other
      else
        render :form, status: :unprocessable_entity
      end
    end

    def destroy
      if @definition.destroy
        render_success_flash_message_via_turbo_stream(message: I18n.t(:notice_successful_delete))
      else
        render_error_flash_message_via_turbo_stream(message: join_flash_messages(@definition.errors.full_messages))
      end

      update_definitions_via_turbo_stream

      respond_to_with_turbo_streams
    end

    def move
      moved = move_after_anchor

      if moved
        update_definitions_via_turbo_stream
        render_success_flash_message_via_turbo_stream(
          message: I18n.t(:"settings.project_phase_definitions.order_changed")
        )
      else
        render_error_flash_message_via_turbo_stream(message: join_flash_messages(@definition.errors.full_messages))
      end

      respond_with_turbo_streams(status: moved ? :ok : :unprocessable_entity)
    end

    private

    def require_enterprise_token
      render_402 unless allowed_to_customize_life_cycle?
    end

    def find_definitions
      @definitions = Project::PhaseDefinition.with_project_count
    end

    def find_definition
      @definition = Project::PhaseDefinition.find(params[:id])
    end

    def definition_params
      params.expect(project_phase_definition: %i[type
                                                 name
                                                 color_id
                                                 start_gate_name
                                                 finish_gate_name
                                                 start_gate
                                                 finish_gate])
    end

    def drop_params
      @drop_params ||= params.permit(:list_type, :list_id, :prev_id)
    end

    def sortable_list_type
      Project::PhaseDefinition.model_name.param_key
    end

    def update_definitions_via_turbo_stream
      update_via_turbo_stream(
        component: Settings::ProjectPhaseDefinitions::IndexComponent.new(
          definitions: find_definitions
        )
      )
    end

    def move_after_anchor
      return false unless valid_drop_request?

      @definition.move_after_anchor(drop_params[:prev_id], scope: Project::PhaseDefinition.all)
    end

    def valid_drop_request?
      drop_params[:list_type] == sortable_list_type &&
        unscoped_list_id? &&
        drop_params.key?(:prev_id)
    end

    # The raw param is checked because permit cannot tell an absent
    # value from a filtered-out array or hash.
    def unscoped_list_id?
      params[:list_id].nil? || params[:list_id] == ""
    end
  end
end
