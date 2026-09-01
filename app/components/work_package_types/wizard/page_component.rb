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
  module Wizard
    class PageComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      def initialize(type:, current_step:, variant: nil, back_url: nil)
        super(type)

        @current_step = current_step
        @back_url = back_url
        # Creating a type hands in the type itself, or nothing at all. Settle what the wizard is
        # editing once here, so nothing below has to ask what it was given.
        @variant = variant.is_a?(TypeVariant) ? variant : type.default_variant
      end

      private

      attr_reader :current_step, :variant, :back_url

      def type = model

      def adding_variant? = variant.present? && !variant.is_default_variant?

      def title
        return I18n.t("types.creation_wizard.add_variant", name: type.name) if adding_variant?

        I18n.t("types.creation_wizard.create_type")
      end

      def breadcrumb_items
        [*helpers.variant_scope_breadcrumb_roots, *parent_breadcrumb_item, title]
      end

      def parent_breadcrumb_item
        []
      end

      def cancel_href
        return back_url if back_url.present?
        return helpers.variant_scope_types_path if helpers.variant_scope_project || !type.persisted?

        edit_type_details_path(type_id: type.id)
      end

      def step_title = Steps.title(current_step)

      def step_url = type_creation_wizard_path(**variant_path_args, step: current_step, back_url:)

      # A type still being created has no variant to address yet.
      def variant_path_args = variant&.path_args || { type_id: type.id }

      # Named here because this route is on the type collection: no segment of the request
      # matches it, so the form would otherwise post to administration.
      def step_form_url
        return step_url if record_persisted?

        scope = { in_project_id: helpers.variant_scope_project, back_url: }

        return creation_wizard_types_path(type_id: type.id, **scope) if adding_variant?

        creation_wizard_types_path(**scope)
      end

      def step_form_method
        record_persisted? ? :patch : :post
      end

      def record_persisted?
        adding_variant? ? variant.persisted? : type.persisted?
      end

      # Editors whose fields belong to the wizard form itself, so that "Continue"
      # persists them when advancing to the next step.
      def step_editor
        @step_editor ||= StepEditors.for(current_step, editor_record)
      end

      def editor_record
        return variant if adding_variant?

        current_step == :details || type.new_record? ? type : type.default_variant
      end

      def step_form_options
        {
          model: step_editor.model,
          url: step_form_url,
          method: step_form_method,
          readonly: step_editor.readonly?,
          html: {
            id: WorkPackageTypes::Wizard::FooterComponent::FORM_IDENTIFIER,
            # Advancing replaces the whole page, so submission must escape the frame.
            data: { turbo_frame: "_top" }.merge(step_editor.form_data)
          }
        }
      end

      # Only a step with a reuse mode needs the frame, and only those steps are reached
      # with a persisted type — step_url has no route while the record is still new.
      def within_step_frame(&)
        return capture(&) unless step_editor.linkable_aspect?

        render(
          WorkPackageTypes::ReloadableConfigurationFrameComponent.new(
            reload_url: step_url,
            reload_from_location: step_editor.reload_from_location?
          ),
          &
        )
      end

      def reuse_mode_banner
        return unless step_editor.linkable_aspect?

        render(WorkPackageTypes::ReuseModeBannerComponent.new(variant:, aspect: step_editor.aspect))
      end

      # Editors that self-persist through their own turbo endpoints.
      def step_body
        case current_step
        when :form_configuration
          FormConfigurationStepComponent.new(variant:)
        when :project_attributes
          ProjectAttributesStepComponent.new(variant:)
        when :projects
          WorkPackageTypes::ProjectsComponent.new(type, variant:, projects: Project.all)
        when :pdf
          PdfStepComponent.new(variant:)
        else
          PlaceholderComponent.new(step: current_step)
        end
      end
    end
  end
end
