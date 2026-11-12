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

module OpenProject
  module StepWizard
    # @logical_path OpenProject/StepWizard
    class FooterPreview < Lookbook::Preview
      # @label Default
      def default
        render_with_template(template: "open_project/step_wizard/footer_preview/playground",
                             locals: { show_back_button: true, show_cancel_button: true, show_progress_bar: true, total_steps: 6,
                                       current_step: 3 })
      end

      # @label Playground
      # @param show_back_button [Boolean]
      # @param show_cancel_button [Boolean]
      # @param show_progress_bar [Boolean]
      # @param total_steps [Integer]
      # @param current_step [Integer]
      def playground(
        show_back_button: true,
        show_cancel_button: true,
        show_progress_bar: true,
        total_steps: 6,
        current_step: 3
      )
        render_with_template(locals: { show_back_button:, show_cancel_button:, show_progress_bar:, total_steps:, current_step: })
      end
    end
  end
end
