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
  # Guided, multi-step creation of a work package variant.
  #
  # Deliberately self-contained: it never reuses the tabbed type controllers so
  # the existing tabbed creation/editing flow keeps working unchanged next to it.
  # The variant record is created after the first step and each later step
  # persists to that same record (see FND-117).
  class CreationWizardController < ApplicationController
    include TypeVariantsFeature

    layout "no_menu"

    before_action :require_admin
    before_action :require_type_variants_feature
    before_action :find_type, only: %i[show update]
    before_action :set_current_step, only: %i[show update]

    def show; end

    def new
      @type = Type.new(parent_id: params[:parent_id])
      @current_step = Wizard::Steps.first
      render :show
    end

    def create
      service_call = WorkPackageTypes::CreateService.new(user: current_user).call(details_params)
      @type = service_call.result

      if service_call.success?
        redirect_to_step Wizard::Steps.next_after(Wizard::Steps.first)
      else
        @current_step = Wizard::Steps.first
        render :show, status: :unprocessable_entity
      end
    end

    def update
      case @current_step
      when :details
        update_details
      when :defaults
        update_defaults
      when :workflows
        update_workflows
      else
        advance
      end
    end

    private

    def update_details
      service_call = WorkPackageTypes::UpdateService
                       .new(user: current_user, model: @type, contract_class: WorkPackageTypes::UpdateDetailsContract)
                       .call(details_params)

      if service_call.success?
        advance
      else
        render :show, status: :unprocessable_entity
      end
    end

    # A Linked aspect renders read-only and submits nothing, so there is nothing to
    # persist and the values on screen belong to the source type.
    def update_defaults
      return advance if @type.linked?(Type::ConfigurationLink::DEFAULTS)

      service_call = WorkPackageTypes::UpdateService
                       .new(user: current_user, model: @type, contract_class: WorkPackageTypes::UpdateDefaultsContract)
                       .call(patterns: Forms::DefaultsFormModel.to_patterns(defaults_params),
                             description: defaults_params[:description])

      if service_call.success?
        advance
      else
        render :show, status: :unprocessable_entity
      end
    end

    # The matrix submits its inputs with the wizard form, along with the roles and
    # transition tab it was showing, so that only that slice is rewritten.
    def update_workflows
      matrix_context = ::Workflows::MatrixContext.new(
        type: @type,
        tab: params[:tab],
        role_ids: params[:role_ids]
      )

      service_call = ::Workflows::MatrixUpdateService
                       .new(type: @type, roles: matrix_context.roles, tab: matrix_context.tab)
                       .call(status: params[:status], indeterminate_status: params[:indeterminate_status])

      if service_call.success?
        advance
      else
        render :show, status: :unprocessable_entity
      end
    end

    def advance
      redirect_to_step Wizard::Steps.next_after(@current_step)
    end

    def redirect_to_step(step)
      if step
        redirect_to type_creation_wizard_path(@type, step:), status: :see_other
      else
        redirect_to types_path, notice: t("types.creation_wizard.success"), status: :see_other
      end
    end

    def find_type
      @type = ::Type.find(params.expect(:type_id))
    end

    def set_current_step
      @current_step = Wizard::Steps.for_key(params[:step]) || Wizard::Steps.first
    end

    # The core settings are only editable while creating a root type; a variant
    # renders them disabled, so the browser never submits them.
    def details_params
      params.expect(type: %i[name parent_id color_id is_milestone is_in_roadmap])
    end

    def defaults_params
      @defaults_params ||= params.expect(
        work_package_types_forms_defaults_form_model: %i[subject_configuration pattern description]
      ).to_h
    end
  end
end
