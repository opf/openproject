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

module OpPrimer
  # A toggle switch that can be locked with a reason.
  #
  # A locked switch is marked `aria-disabled` rather than `disabled`: Primer forbids tooltips on
  # `disabled` elements because they are not keyboard-accessible, and the reason is what we need
  # to convey. Keeping it focusable means it must refuse activation in JavaScript, which the
  # `aria-disabled-guard` controller does.
  class LockableToggleSwitchComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    def initialize(src:, checked:, locked_reason: nil, tooltip_direction: :w, **system_arguments)
      super()

      @src = src
      @checked = checked
      @locked_reason = locked_reason
      @tooltip_direction = tooltip_direction
      @system_arguments = system_arguments
    end

    private

    def locked? = @locked_reason.present?

    def toggle_arguments
      arguments = {
        src: @src,
        csrf_token: helpers.form_authenticity_token,
        checked: @checked,
        turbo: true,
        size: :small,
        status_label_position: :start
      }.deep_merge(@system_arguments)

      arguments[:classes] = class_names(
        @system_arguments[:classes],
        "op-primer-adjustments__toggle-switch--hidden-loading-indicator",
        "ToggleSwitch--disabled" => locked?
      )

      return arguments unless locked?

      arguments.deep_merge(
        data: {
          controller: "lockable-toggle-switch",
          lockable_toggle_switch_button_id_value: button_id
        },
        aria: { disabled: true, describedby: tooltip_id }
      )
    end

    def tooltip_arguments
      {
        id: tooltip_id,
        type: :description,
        for_id: button_id,
        text: @locked_reason,
        direction: @tooltip_direction
      }
    end

    def button_id
      @button_id ||= Primer::Component.generate_id(base_name: "lockable-toggle-switch-button")
    end

    def tooltip_id
      @tooltip_id ||= Primer::Component.generate_id(base_name: "lockable-toggle-switch-tooltip")
    end
  end
end
