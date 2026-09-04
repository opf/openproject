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
  class VariantsController < BaseTabController
    include TypeVariantsFeature
    include OpTurbo::ComponentStream

    before_action :require_type_variants_feature
    administration_only! :index, :make_default, :remove_default, :convert_to_global_dialog, :convert_to_global

    current_menu_item do
      :types
    end

    # The filter input drives the list's turbo frame, so a frame request only needs the list
    # component: Turbo picks the frame out of it and drops the rest.
    def index
      return unless turbo_frame_request?

      render VariantsListComponent.new(type: @type, query: params[:query]), layout: false
    end

    def menu
      render Types::VariantActionsComponent.new(variant: named_variant, back_url: params[:back_url]),
             layout: false
    end

    def deletion_dialog
      variant = named_variant
      targets = variant.migration_targets.in_display_order

      respond_with_dialog Types::DeletionDialogComponent.new(
        variant:, targets:, selected: targets.first, impact: deletion_impact(variant, targets.first),
        url: type_variant_path(type_id: variant.type_id, id: variant.id)
      )
    end

    def deletion_preview
      variant = named_variant

      update_via_turbo_stream(
        component: ::Projects::Settings::WorkPackages::Types::SwitchImpactComponent.new(
          impact: deletion_impact(variant, chosen_target(variant))
        )
      )

      respond_to_with_turbo_streams
    end

    def destroy
      variant = named_variant
      target = chosen_target(variant)
      service_call = DeleteVariantService.new(user: current_user, model: variant).call(target:)

      return repaint_deletion_form(variant, target, service_call) if target && !service_call.success?

      flash_delete_result(service_call)
      redirect_back_or_default(helpers.variant_scope_types_path, status: :see_other)
    end

    def make_default
      apply_default_service(MakeDefaultService, "types.index.make_default_notice")
    end

    def remove_default
      apply_default_service(RemoveDefaultService, "types.index.remove_default_notice")
    end

    def convert_to_global_dialog
      variant = named_variant

      respond_with_dialog Types::ConvertToGlobalDialogComponent.new(
        url: convert_to_global_type_variant_path(type_id: variant.type_id, id: variant.id)
      )
    end

    def convert_to_global
      variant = named_variant
      return flash_convert_blocked if variant.inherits_from_project_owned_variant?

      service_call = ConvertToGlobalService.new(variant:).call

      if service_call.success?
        flash[:notice] = t("types.index.convert_to_global_notice", name: variant.composite_name)
      else
        flash[:error] = service_call.errors.full_messages
      end

      redirect_back_or_default(types_path, status: :see_other)
    end

    private

    def flash_convert_blocked
      render_error_flash_message_via_turbo_stream(message: t("types.index.convert_to_global_blocked"))
      respond_with_turbo_streams
    end

    def find_variant; end

    # Unlike the actions above, either variant of a type can be the one new projects start
    # with, so the base one is addressable here too.
    def any_variant
      @type.variants.find(params.expect(:id))
    end

    def apply_default_service(service, notice_key)
      variant = any_variant
      service_call = service.new(variant:, user: current_user).call

      if service_call.success?
        flash[:notice] = t(notice_key, name: variant.composite_name)
      else
        flash[:error] = service_call.errors.full_messages
      end

      redirect_back_or_default(types_path, status: :see_other)
    end

    # A project reaches only the variants it owns, so another project's is absent rather than
    # refused after the fact.
    def named_variant
      addressable = @type.variants.non_default_variants
      addressable = addressable.owned_by(variant_scope_project) if variant_scope_project

      addressable.find(params.expect(:id))
    end

    def chosen_target(variant)
      return if params[:target_id].blank?

      variant.migration_targets.find_by(id: params[:target_id])
    end

    def flash_delete_result(service_call)
      if service_call.success?
        flash[:notice] = t(:notice_successful_delete)
      else
        flash[:error] = service_call.errors.full_messages.to_sentence
      end
    end

    # The impact spans every project applying the variant,
    # so work packages are passed in rather than scoping Impact to a particular project.
    def deletion_impact(variant, target)
      return if target.nil?

      ::Projects::Types::Switch::Impact.new(source: variant, target:, work_packages: variant.work_packages)
    end

    def repaint_deletion_form(variant, target, service_call)
      update_via_turbo_stream(
        component: Types::DeletionFormComponent.new(
          variant:, targets: variant.migration_targets.in_display_order, selected: target,
          impact: deletion_impact(variant, target),
          url: type_variant_path(type_id: variant.type_id, id: variant.id),
          validation_message: service_call.errors.full_messages.to_sentence
        )
      )

      respond_to_with_turbo_streams
    end
  end
end
