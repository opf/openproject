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

module Components
  module WorkPackages
    class MoveDialog
      include Capybara::DSL
      include Capybara::RSpecMatchers
      include RSpec::Matchers
      include WaitHelpers

      def initialize(dialog_id: "wp-move-dialog")
        @dialog_id = dialog_id
      end

      attr_reader :dialog_id

      def dialog_css_selector
        "dialog##{dialog_id}"
      end

      def within_dialog(&)
        dialog = find(dialog_css_selector)
        wait_for_size_animation_completion(dialog)
        within(dialog, &)
      end

      def expect_open
        expect(page).to have_css(dialog_css_selector)
      end

      def expect_descendants_choice
        within_dialog do
          expect(page).to have_text "Move all descendants too?"
        end
      end

      def expect_permission_banner
        within_dialog { expect(page).to have_text permission_banner }
      end

      def expect_no_permission_banner
        within_dialog { expect(page).to have_no_text permission_banner }
      end

      # "Move just this work package" is preselected, so continuing moves only the root(s).
      def continue_with_root_only
        within_dialog { click_button continue_button }
      end

      def continue_with_descendants
        within_dialog do
          choose choice_label("with_descendants_label"), allow_label_click: true
          expect(page).to have_checked_field(choice_label("with_descendants_label"), visible: :all)
          click_button continue_button
        end
      end

      private

      def choice_label(key)
        I18n.t("work_packages.move_dialog_shared.descendants_choice.#{key}")
      end

      def permission_banner
        I18n.t("work_packages.move_dialog_shared.permission_banner")
      end

      def continue_button
        I18n.t(:button_continue)
      end
    end
  end
end
