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

      def initialize(type:, current_step:)
        super(type)

        @current_step = current_step
      end

      private

      attr_reader :current_step

      def type = model

      def title = I18n.t("types.creation_wizard.create_subtype")

      def breadcrumb_items
        [
          { href: admin_index_path, text: I18n.t("label_administration") },
          { href: admin_settings_work_packages_general_path, text: I18n.t(:label_work_package_plural) },
          { href: types_path, text: I18n.t(:label_type_plural) },
          title
        ]
      end

      def step_title = Steps.title(current_step)

      def step_url = type_creation_wizard_path(type, step: current_step)

      # A brand-new sub-type is created on the first step's submit; every later
      # submit patches the existing record for its step.
      def step_form_url
        type.new_record? ? creation_wizard_types_path : step_url
      end

      def step_form_method
        type.new_record? ? :post : :patch
      end

      # Editors whose fields belong to the wizard form itself, so that "Continue"
      # persists them when advancing to the next step.
      def step_editor_form
        case current_step
        when :details
          DetailsForm
        when :workflows
          WorkflowsForm
        end
      end

      # Editors that self-persist through their own turbo endpoints.
      def step_body
        case current_step
        when :defaults
          DefaultsStepComponent.new(type:)
        when :form_configuration
          FormConfigurationStepComponent.new(type:)
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
