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
  # Guided, multi-step creation of a work package type, or of a variant of one.
  #
  # Both modes are the same walk: the first step names the thing being created, and every step
  # after it configures exactly one variant — the type's base variant when creating a type, the
  # new named variant when adding one. `@variant` is that configuration throughout, so the later
  # steps do not care which mode they are in.
  #
  # Deliberately self-contained: it never reuses the tabbed type controllers so
  # the existing tabbed creation/editing flow keeps working unchanged next to it.
  # The record is created after the first step and each later step persists to it (see FND-117).
  class CreationWizardController < ApplicationController
    include TypeVariantsFeature

    layout "no_menu"

    helper_method :adding_variant?

    before_action :require_admin
    before_action :require_type_variants_feature
    before_action :find_type, only: %i[show update]
    before_action :find_variant, only: %i[show update]
    before_action :set_current_step, only: %i[show update]

    def show; end

    # Naming a type creates one; naming a type that already exists adds a variant to it.
    def new
      if params[:type_id]
        @type = ::Type.find(params.expect(:type_id))
        @variant = @type.variants.new
      else
        @type = Type.new
      end

      @current_step = Wizard::Steps.first
      render :show
    end

    def create
      params[:type_id] ? create_variant : create_type
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

    def create_type
      service_call = WorkPackageTypes::CreateService.new(user: current_user).call(details_params)
      @type = @variant = service_call.result

      if service_call.success?
        redirect_to_step Wizard::Steps.next_after(Wizard::Steps.first)
      else
        @current_step = Wizard::Steps.first
        render :show, status: :unprocessable_entity
      end
    end

    # A new variant starts out Linked to the type's base variant for every aspect, which is what
    # makes it a variation of that configuration rather than an empty one. Each later step
    # switches its own aspect to Independent if the administrator edits it.
    def create_variant
      @type = ::Type.find(params.expect(:type_id))
      @variant = @type.variants.new(variant_details_params)

      TypeVariant::ASPECTS.each { @variant.public_send(:"#{it}_source=", @type.default_variant) }

      if @variant.save
        redirect_to_step Wizard::Steps.next_after(Wizard::Steps.first)
      else
        @current_step = Wizard::Steps.first
        render :show, status: :unprocessable_entity
      end
    end

    def update_details
      return update_variant_details if adding_variant?

      service_call = WorkPackageTypes::UpdateService
                       .new(user: current_user, model: @type, contract_class: WorkPackageTypes::UpdateDetailsContract)
                       .call(details_params)

      if service_call.success?
        advance
      else
        render :show, status: :unprocessable_entity
      end
    end

    def update_variant_details
      if @variant.update(variant_details_params)
        advance
      else
        render :show, status: :unprocessable_entity
      end
    end

    # A Linked aspect renders read-only and submits nothing, so there is nothing to
    # persist and the values on screen belong to the source type.
    def update_defaults
      return advance if @variant.linked?(TypeVariant::DEFAULTS)

      service_call = WorkPackageTypes::UpdateService
                       .new(user: current_user, model: @variant,
                            contract_class: WorkPackageTypes::UpdateDefaultsContract)
                       .call(patterns: Forms::DefaultsFormModel.to_patterns(defaults_params),
                             default_work_package_description: defaults_params[:default_work_package_description])

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
        variant: @variant,
        tab: params[:tab],
        role_ids: params[:role_ids]
      )

      service_call = ::Workflows::MatrixUpdateService
                       .new(variant: @variant, roles: matrix_context.roles, tab: matrix_context.tab)
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
        redirect_to type_creation_wizard_path(**variant_path_args, step:), status: :see_other
      else
        redirect_to types_path, notice: t("types.creation_wizard.success"), status: :see_other
      end
    end

    # The variant only reaches the path while a named one is being added: the base variant is
    # implied by its type, and naming it would make every type-creation URL carry a redundant id.
    def variant_path_args
      return { type_id: @type.id } unless adding_variant?

      { type_id: @type.id, variant_id: @variant.id }
    end

    def adding_variant? = @variant.is_a?(TypeVariant) && !@variant.is_default_variant?

    def find_type
      @type = ::Type.find(params.expect(:type_id))
    end

    # Always the configuration the later steps edit, whichever mode the wizard is in.
    def find_variant
      @variant = if params[:variant_id]
                   @type.variants.named.find(params.expect(:variant_id))
                 else
                   @type.default_variant
                 end
    end

    def set_current_step
      @current_step = Wizard::Steps.for_key(params[:step]) || Wizard::Steps.first
    end

    # The wizard creates a type, which is identity only. Its configuration lands on the base
    # variant the type creates for itself.
    def details_params
      params.expect(type: %i[name color_id is_milestone is_in_roadmap])
    end

    def variant_details_params
      params.expect(type_variant: [:variant_name])
    end

    def defaults_params
      @defaults_params ||= params.expect(
        work_package_types_forms_defaults_form_model: %i[subject_configuration pattern default_work_package_description]
      ).to_h
    end
  end
end
