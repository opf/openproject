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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackageTypes
  class VariantsController < BaseTabController
    include OpTurbo::ComponentStream
    include WorkPackageTypes::AdminTypesList

    LIST_VIEW_STATE_KEYS = %w[page per_page query created_by_migration].freeze

    current_menu_item do
      :types
    end

    # The filter input drives the list's turbo frame, so a frame request only needs the list
    # component: Turbo picks the frame out of it and drops the rest.
    def index
      return unless turbo_frame_request?

      render VariantsListComponent.new(type: @type, query: params[:query], created_by_migration: params[:created_by_migration]),
             layout: false
    end

    def comparison
      @comparison = VariantComparison.new(type: @type)
    end

    def menu
      render Types::VariantActionsComponent.new(variant: named_variant, back_url: params[:back_url]),
             layout: false
    end

    def deletion_dialog
      variant = named_variant

      if variant.project_types.exists?
        respond_with_dialog migration_deletion_dialog(variant)
      else
        respond_with_dialog Types::UnusedVariantDeletionDialogComponent.new(
          variant:, url: deletion_path(variant)
        )
      end
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

      restore_list_view_state
      replace_variant_list(variant, target, service_call)
    end

    def make_default
      apply_default_service(MakeDefaultService, "types.index.make_default_notice")
    end

    def remove_default
      apply_default_service(RemoveDefaultService, "types.index.remove_default_notice")
    end

    def convert_to_global_dialog
      dialog_via_turbo_stream(component: convert_confirm_dialog(named_variant))
      respond_with_turbo_streams
    end

    def convert_to_global
      variant = named_variant
      service_call = ConvertToGlobalService.new(variant:).call(name: requested_name)

      if service_call.success?
        flash[:notice] = t("types.index.convert_to_global_notice", name: variant.composite_name)
        return redirect_back_or_default(types_path, status: :see_other)
      end

      handle_failed_convert(service_call)
      respond_with_turbo_streams
    end

    private

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

    def migration_deletion_dialog(variant)
      targets = variant.migration_targets.in_display_order

      Types::VariantDeletionDialogComponent.new(
        variant:, targets:, selected: targets.first, impact: deletion_impact(variant, targets.first),
        url: deletion_path(variant)
      )
    end

    def deletion_path(variant)
      variant_path(variant_scope_project, variant, back_url: params[:back_url])
    end

    def chosen_target(variant)
      return if params[:target_id].blank?

      variant.migration_targets.find_by(id: params[:target_id])
    end

    # The impact spans every project applying the variant,
    # so work packages are passed in rather than scoping Impact to a particular project.
    def deletion_impact(variant, target)
      return if target.nil?

      ::Projects::Types::Switch::Impact.new(source: variant, target:, work_packages: variant.work_packages)
    end

    # The list the delete was triggered from is on the same page, so repaint it in place with a
    # morph to keep scroll position and the type's expanded state instead of redirecting away.
    def replace_variant_list(variant, target, service_call)
      dialog_id = target ? Types::VariantDeletionDialogComponent::DIALOG_ID : Types::UnusedVariantDeletionDialogComponent::DIALOG_ID
      close_dialog_via_turbo_stream(dialog_id)

      replace_via_turbo_stream(component: variant_list_component(variant), method: :morph)

      if service_call.success?
        render_success_flash_message_via_turbo_stream(message: t(:notice_successful_delete))
      else
        render_error_flash_message_via_turbo_stream(message: service_call.errors.full_messages.to_sentence)
      end

      respond_with_turbo_streams(status: service_call)
    end

    def variant_list_component(variant)
      if variant_scope_project
        ::Projects::Settings::WorkPackages::Types::ListComponent.new(
          project: variant_scope_project.reload,
          created_by_migration: params[:created_by_migration] == MigrationFilterComponent::MIGRATED,
          expanded_type_id: variant.type_id
        )
      elsif deletion_from_variants_tab?
        VariantsListComponent.new(type: @type.reload, query: params[:query],
                                  created_by_migration: params[:created_by_migration])
      else
        admin_types_list_component(expanded_type_id: variant.type_id)
      end
    end

    def deletion_from_variants_tab?
      params[:back_url].to_s.start_with?(type_variants_path(type_id: @type.id))
    end

    # A deletion posts from a paginated/filtered list, but that state travels inside
    # back_url. Restore so morphing keeps the same state
    def restore_list_view_state
      search = params[:back_url].to_s.split("?", 2).second
      return if search.blank?

      restored = Rack::Utils.parse_nested_query(search)
                            .slice(*LIST_VIEW_STATE_KEYS)
                            .select { |_, value| value.is_a?(String) }
      params.merge!(restored)
    end

    def repaint_deletion_form(variant, target, service_call)
      update_via_turbo_stream(
        component: Types::DeletionFormComponent.new(
          variant:, targets: variant.migration_targets.in_display_order, selected: target,
          impact: deletion_impact(variant, target),
          url: deletion_path(variant),
          validation_message: service_call.errors.full_messages.to_sentence
        )
      )

      respond_to_with_turbo_streams
    end

    def handle_failed_convert(service_call)
      if params.key?(:type_variant)
        repaint_rename_form(service_call)
      else
        open_rename_dialog
      end
    end

    def open_rename_dialog
      close_dialog_via_turbo_stream(Types::ConvertToGlobalDialogComponent::DIALOG_ID)
      variant = named_variant # Fresh version, no preexisting errors
      dialog_via_turbo_stream(component: Types::ConvertToGlobalRenameDialogComponent.new(
        variant:, url: convert_path(variant)
      ))
    end

    def repaint_rename_form(service_call)
      update_via_turbo_stream(
        component: Types::ConvertToGlobalRenameFormComponent.new(
          variant: service_call.result, url: convert_path(service_call.result)
        ),
        status: :unprocessable_entity
      )
    end

    def requested_name
      params.dig(:type_variant, :variant_name)
    end

    def convert_confirm_dialog(variant)
      Types::ConvertToGlobalDialogComponent.new(variant:, url: convert_path(variant))
    end

    def convert_path(variant)
      convert_to_global_type_variant_path(type_id: variant.type_id, id: variant.id)
    end
  end
end
