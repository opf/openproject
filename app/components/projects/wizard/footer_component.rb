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

module Projects
  module Wizard
    class FooterComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      def initialize(form_identifier:, project:, custom_fields_by_section:, current_step:)
        @form_identifier = form_identifier
        @project = project
        @custom_fields_by_section = custom_fields_by_section
        @current_step = current_step

        super
      end

      def call
        render(StepWizard::FooterComponent.new(form_identifier:, total_steps:, current_step: current_step + 1)) do |footer|
          footer.with_back_button(href: back_button_href)
          footer.with_cancel_button(href: cancel_button_href)
          footer.with_continue_button(**continue_button_args)
          footer.with_submit_button(**submit_button_args)
          footer.with_progress_bar
        end
      end

      private

      attr_reader :form_identifier, :project, :custom_fields_by_section, :current_step

      def sections
        @sections ||= custom_fields_by_section.keys
      end

      def total_steps
        sections.count
      end

      def back_button_href
        if previous_step
          project_creation_wizard_path(project, section: sections[previous_step].id)
        end
      end

      def cancel_button_href
        project_path(project)
      end

      def continue_button_args
        {
          form: form_identifier,
          name: "next_section",
          value: sections[next_step]&.id
        }
      end

      def submit_button_args
        {
          form: form_identifier,
          name: "finish",
          value: "true"
        }
      end

      def next_step
        return nil if current_step >= total_steps

        current_step + 1
      end

      def previous_step
        return nil if current_step == 0

        current_step - 1
      end
    end
  end
end
