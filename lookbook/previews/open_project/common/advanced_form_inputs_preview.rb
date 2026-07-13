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

module OpenProject
  module Common
    # @logical_path OpenProject/Common
    class AdvancedFormInputsPreview < Lookbook::Preview
      def advanced_radio_button_group
        render_with_template
      end

      def advanced_check_box_group
        render_with_template
      end

      # `check_box_group` with `include_hidden: true`
      #
      # HTML forms do not submit unchecked checkboxes, so when every option in an
      # array-valued `check_box_group` is unchecked, the field key is absent from
      # the request params entirely. The server then has no way to distinguish
      # "user cleared all selections" from "this field was not part of the form",
      # and the previous value is silently preserved.
      #
      # Pass `include_hidden: true` to emit a hidden sentinel field before the
      # checkboxes. This mirrors the behaviour of Rails' own `check_box` helper
      # and ensures the key is always present in params — as an empty array when
      # nothing is checked — so the server can save the empty selection correctly.
      def check_box_group_with_include_hidden
        render_with_template
      end

      # **SegmentedControlInput**
      #
      # A Primer `SegmentedControl` backed by a plain `<input type="hidden">`.
      # The hidden field is the source of truth for form submission: when the
      # user selects a segment, the `filter--segmented-control` Stimulus
      # controller reacts to Primer's `itemActivated` event, writes the chosen
      # `data-value` into the hidden field, and dispatches a `change` event so
      # that any ancestor change listener (e.g. `filter--filters-form`) can
      # react without knowing about the segmented control at all.
      #
      # The first item is selected by default when `value:` is nil or absent.
      def segmented_control_input_multi
        render_with_template
      end

      # **SegmentedControlInput — boolean toggle**
      #
      # A special case of `SegmentedControlInput` with exactly two items
      # mimicking a toggle switch. Used for boolean filters where the backing
      # values are `"t"` (yes) and `"f"` (no).
      def segmented_control_input_boolean
        render_with_template
      end
    end
  end
end
