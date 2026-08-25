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

module Projects
  module Settings
    module WorkPackages
      module Types
        # The switch dialog's form. Separate from the dialog so a refused switch can replace
        # it: replacing the dialog component would swap out the <dialog> element and close it.
        class SwitchFormComponent < ApplicationComponent
          include OpPrimer::ComponentHelpers
          include OpTurbo::Streamable

          def initialize(project:, source:, url:, selected: source, validation_message: nil)
            super()

            @project = project
            @source = source
            @url = url
            @selected = selected
            @validation_message = validation_message
          end

          private

          attr_reader :project, :source, :url, :selected, :validation_message

          def available_targets
            source.type.variants.in_display_order
          end

          # The route addresses the type, as the switch route does: the variant is what the
          # project resolves it to, and the form body carries which one is being asked about.
          def impact_path
            project_settings_work_packages_type_switch_impact_path(project, source.type)
          end

          # The one place the container leaks in: a page hosting the same fields
          # would declare its own form and need the same wiring.
          def refresh_data
            {
              controller: "refresh-on-form-changes",
              refresh_on_form_changes_target: "form",
              refresh_on_form_changes_turbo_stream_url_value: impact_path
            }
          end

          # Constant lookup in a compiled template does not walk the enclosing modules.
          def dialog_id
            SwitchDialogComponent::DIALOG_ID
          end
        end
      end
    end
  end
end
