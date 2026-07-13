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

      # Config-link aspect backing the current step's reuse mode. Details has none:
      # it names the type (and is still unpersisted on the first step), so there is
      # nothing to reuse from a source.
      def step_aspect
        case current_step.key
        when :form_configuration
          Type::ConfigurationLink::FORM_CONFIGURATION
        when :workflows
          Type::ConfigurationLink::WORKFLOWS
        when :automations
          Type::ConfigurationLink::AUTOMATIONS
        when :projects
          Type::ConfigurationLink::PROJECTS
        when :pdf
          Type::ConfigurationLink::PDF_EXPORT
        end
      end

      def step_body
        case current_step.key
        when :details
          DetailsComponent.new(type:)
        when :form_configuration
          FormConfigurationStepComponent.new(type:)
        when :workflows
          WorkflowsStepComponent.new(type:)
        when :projects
          WorkPackageTypes::ProjectsComponent.new(type, projects: Project.all)
        when :pdf
          WorkPackageTypes::ExportConfigurationComponent.new(type)
        else
          PlaceholderComponent.new(step: current_step)
        end
      end
    end
  end
end
