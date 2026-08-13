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
# See COPYRIGHT and LICENSE files for more details.
#++

module Projects::Settings::WorkPackages::Types::Variants
  # Creating and stepping through a variant the project owns. Only variant creation is reachable
  # here: a type itself is still created in administration.
  class CreationWizardController < ::WorkPackageTypes::CreationWizardController
    include ::WorkPackageTypes::TypeVariantsFeature

    menu_item :settings_work_packages

    skip_before_action :require_admin
    skip_before_action :find_type, raise: false
    skip_before_action :find_variant, raise: false
    # set_current_step decides whether the variant even has the requested step, so it follows
    # the re-registered lookups rather than keeping its inherited position ahead of them.
    skip_before_action :set_current_step, raise: false

    before_action :find_project_by_project_id
    before_action :authorize
    before_action :require_type_variants_feature
    # rubocop:disable Rails/LexicallyScopedActionFilter -- these actions are inherited
    before_action :find_type, only: %i[new create show update]
    before_action :find_variant, only: %i[show update]
    before_action :set_current_step, only: %i[show update]
    # rubocop:enable Rails/LexicallyScopedActionFilter

    def new
      @variant = @type.variants.new(project: @project)
      @current_step = ::WorkPackageTypes::Wizard::Steps.first

      render :show
    end

    def create = create_variant

    private

    def find_type
      @type = ::Type.find(params.expect(:type_id))
    end

    # A variant of another project is absent rather than forbidden.
    def find_variant
      @variant = @type.variants.non_default_variants.owned_by(@project).find_by(id: params[:variant_id])

      render_404 if @variant.nil?
    end

    # A step the variant does not have is not merely hidden from the sidebar: reaching it by
    # URL must not render it either.
    def set_current_step
      @current_step = ::WorkPackageTypes::Wizard::Steps.for_key(params[:step]) ||
                      ::WorkPackageTypes::Wizard::Steps.first

      render_404 unless ::WorkPackageTypes::Wizard::Steps.available?(@current_step, @variant)
    end

    # The owner comes from the route, never from the request body.
    def create_variant
      service_call = ::WorkPackageTypes::CreateVariantService
                       .new(user: current_user, type: @type, project: @project)
                       .call(variant_details_params)
      @variant = service_call.result

      if service_call.success?
        redirect_to_step ::WorkPackageTypes::Wizard::Steps.next_after(
          ::WorkPackageTypes::Wizard::Steps.first, @variant
        )
      else
        @current_step = ::WorkPackageTypes::Wizard::Steps.first
        render :show, status: :unprocessable_entity
      end
    end

    def redirect_to_step(step)
      if step
        redirect_to project_settings_work_packages_type_creation_wizard_path(
          @project, @type, variant_id: @variant.id, step:
        ), status: :see_other
      else
        redirect_to project_settings_work_packages_types_path(@project),
                    notice: t("types.creation_wizard.success"),
                    status: :see_other
      end
    end
  end
end
