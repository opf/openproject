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

      def initialize(type:, current_step:, routes: nil)
        super(type)

        @current_step = current_step
        @routes = routes || TypeRoutes.for(type)
      end

      private

      attr_reader :current_step, :routes

      def type = model

      def title
        if type.variant?
          I18n.t("types.creation_wizard.create_variant")
        else
          I18n.t("types.creation_wizard.create_type")
        end
      end

      def breadcrumb_items
        [*routes.breadcrumb_root_items, *parent_breadcrumb_item, title]
      end

      # Inside a project the parent is administered somewhere the reader cannot go, so it
      # names the family as plain text rather than a link that would refuse them.
      def parent_breadcrumb_item
        return [] if type.parent.nil?

        href = routes.parent_details
        [href ? { href:, text: type.parent.name } : type.parent.name]
      end

      def cancel_href
        type.persisted? ? routes.details : routes.index
      end

      def step_title = Steps.title(current_step)

      def step_url = routes.wizard(step: current_step)

      # A brand-new variant is created on the first step's submit; every later
      # submit patches the existing record for its step.
      def step_form_url
        type.new_record? ? routes.wizard_submit : step_url
      end

      def step_form_method
        type.new_record? ? :post : :patch
      end

      # Editors whose fields belong to the wizard form itself, so that "Continue"
      # persists them when advancing to the next step.
      def step_editor
        @step_editor ||= StepEditors.for(current_step, type)
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

        render(WorkPackageTypes::ReuseModeBannerComponent.new(type:, aspect: step_editor.aspect, routes:))
      end

      # Editors that self-persist through their own turbo endpoints.
      def step_body
        case current_step
        when :form_configuration
          FormConfigurationStepComponent.new(type:)
        when :project_attributes
          ProjectAttributesStepComponent.new(type:)
        when :projects
          WorkPackageTypes::ProjectsComponent.new(type, projects: Project.all)
        when :pdf
          PdfStepComponent.new(type:)
        else
          PlaceholderComponent.new(step: current_step)
        end
      end
    end
  end
end
