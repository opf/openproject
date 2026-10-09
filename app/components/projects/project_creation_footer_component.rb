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
  class ProjectCreationFooterComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    def initialize(form_identifier:, project:, template:, current_step:, cancel_href:)
      @form_identifier = form_identifier
      @project = project
      @template = template
      @current_step = current_step
      @cancel_href = cancel_href

      super
    end

    def call
      render(StepWizard::FooterComponent.new(form_identifier:, total_steps:, current_step:)) do |footer|
        footer.with_cancel_button(href: cancel_href)
        footer.with_continue_button(**continue_button_args)
        footer.with_submit_button(**submit_button_args)
        if show_progress_bar?
          footer.with_progress_bar
        end
      end
    end

    attr_reader :form_identifier, :project, :template, :current_step, :cancel_href

    private

    def show_progress_bar?
      current_step > 1
    end

    def continue_button_args
      {
        form: form_identifier,
        name: "next_section"
      }
    end

    def submit_button_args
      {
        form: form_identifier,
        name: "finish",
        value: "true"
      }
    end

    def total_steps
      template.nil? && project.available_custom_fields.for_all.required.any? ? 3 : 2
    end
  end
end
