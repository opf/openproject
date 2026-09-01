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
  class CreationWizardController < ApplicationController
    include AddressesVariant
    include ::WorkPackageTypes::ConfiguredInScope
    include TypeVariantsFeature

    layout "no_side_menu"

    helper_method :adding_variant?
    before_action :require_type_variants_feature
    before_action :find_type, only: %i[show update]
    before_action :find_variant, only: %i[show update]
    before_action :set_current_step, only: %i[show update]
    before_action :set_back_url

    def show; end

    def new
      if params[:type_id]
        @type = ::Type.find(params.expect(:type_id))
        @variant = @type.variants.new(project: variant_scope_project)
      else
        return render_404 if variant_scope_project # a type itself is created in administration

        @type = Type.new
      end

      @current_step = Wizard::Steps.first
      render :show
    end

    def create
      return create_variant if params[:type_id]
      return render_404 if variant_scope_project # a type itself is created in administration

      create_type
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
        redirect_to_step Wizard::Steps.next_after(Wizard::Steps.first, @variant)
      else
        @current_step = Wizard::Steps.first
        render :show, status: :unprocessable_entity
      end
    end

    def create_variant
      @type = ::Type.find(params.expect(:type_id))
      service_call = WorkPackageTypes::CreateVariantService
                       .new(user: current_user, type: @type)
                       .call(new_variant_params)
      @variant = service_call.result

      if service_call.success?
        redirect_to_step Wizard::Steps.next_after(Wizard::Steps.first, @variant)
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
      service_call = WorkPackageTypes::UpdateService
                       .new(user: current_user, model: @variant, contract_class: UpdateVariantContract)
                       .call(variant_details_params)

      if service_call.success?
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
      redirect_to_step Wizard::Steps.next_after(@current_step, @variant)
    end

    def redirect_to_step(step)
      if step
        redirect_to type_creation_wizard_path(**variant_path_args, step:, back_url: @back_url), status: :see_other
      else
        flash[:notice] = t("types.creation_wizard.success")
        redirect_back_or_default(finished_path, status: :see_other)
      end
    end

    # The wizard hands this straight to the cancel button, so it is validated here rather than
    # where it is rendered.
    def set_back_url
      @back_url = RedirectPolicy.new(params[:back_url], hostname: request.host, default: nil).redirect_url
    end

    # types_path carries no project, so naming it while scoped would append the project as a query
    # parameter and land on a screen the caller cannot open.
    def finished_path
      return types_path if variant_scope_project.nil?

      project_settings_work_packages_types_path(variant_scope_project)
    end

    # @variant is the type itself while a type is being created until there is a variant to be used
    def variant_path_args
      adding_variant? ? @variant.path_args : { type_id: @type.id }
    end

    def adding_variant? = @variant.is_a?(TypeVariant) && !@variant.is_default_variant?

    def find_type
      @type = ::Type.find(params.expect(:type_id))
    end

    def addressed_type = @type

    def find_variant
      @variant = addressed_variant(among: @type.variants.non_default_variants)
    end

    def set_current_step
      @current_step = Wizard::Steps.for_key(params[:step]) || Wizard::Steps.first

      render_404 unless Wizard::Steps.available?(@current_step, @variant)
    end

    def details_params
      params.expect(type: %i[name color_id is_milestone is_in_roadmap])
    end

    def variant_details_params
      params.expect(type_variant: [:variant_name])
    end

    # The owner is the project this was routed through, merged last so that it wins over anything
    # the body carries under that name.
    def new_variant_params
      variant_details_params.to_h.merge(project: variant_scope_project)
    end

    def defaults_params
      @defaults_params ||= params.expect(
        work_package_types_forms_defaults_form_model: %i[subject_configuration pattern default_work_package_description]
      ).to_h
    end
  end
end
