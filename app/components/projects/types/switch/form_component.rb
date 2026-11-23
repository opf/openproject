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
  module Types
    module Switch
      # Separate from the dialog so a refused target can repaint it in place: replacing the dialog
      # would swap out the <dialog> element and close it.
      class FormComponent < ApplicationComponent
        include OpPrimer::ComponentHelpers
        include OpTurbo::Streamable

        def initialize(selection:, selected:, confirmation_url:, impact_url:, params: {}, validation_message: nil)
          super()

          @selection = selection
          @selected = selected
          @confirmation_url = confirmation_url
          @impact_url = impact_url
          @params = params
          @validation_message = validation_message
        end

        private

        attr_reader :selection, :selected, :confirmation_url, :impact_url, :params, :validation_message

        def form_data
          {
            turbo_stream: true,
            controller: "refresh-on-form-changes",
            refresh_on_form_changes_target: "form",
            refresh_on_form_changes_turbo_stream_url_value: impact_url
          }
        end

        def dialog_id = DialogComponent::DIALOG_ID
      end
    end
  end
end
