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
        class SwitchForm < ApplicationForm
          def initialize(targets:, selected:, validation_message: nil)
            super()

            @targets = targets
            @selected = selected
            @validation_message = validation_message
          end

          form do |switch_form|
            switch_form.select_list(
              name: :target_id,
              label: I18n.t("projects.settings.types.switch.target_label"),
              include_blank: false,
              validation_message: @validation_message,
              data: {
                test_selector: "project-types-switch-select",
                action: "change->refresh-on-form-changes#triggerTurboStream"
              }
            ) do |list|
              # Composite rather than own names: repeating the family on every
              # option is what makes it evident that nothing outside it is on offer.
              @targets.each do |target|
                list.option(value: target.id, label: target.composite_name, selected: target == @selected)
              end
            end
          end
        end
      end
    end
  end
end
