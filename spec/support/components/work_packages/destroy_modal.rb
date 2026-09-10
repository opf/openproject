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

module Components
  module WorkPackages
    class DestroyModal
      include Capybara::DSL
      include Capybara::RSpecMatchers
      include RSpec::Matchers

      def initialize(bulk_mode: false, dialog_id: "wp-delete-dialog")
        @bulk_mode = bulk_mode
        @dialog_id = dialog_id
      end

      attr_reader :dialog_id

      def dialog_css_selector
        "dialog##{dialog_id}"
      end

      def within_dialog(&)
        within(dialog_css_selector, &)
      end

      def expect_open
        expect(page).to have_css(dialog_css_selector)
      end

      def expect_listed(*work_packages)
        within_dialog do
          work_packages.each do |work_package|
            expect(page).to have_text(work_package.subject)
          end
        end
      end

      def confirm_deletion
        within_dialog do
          # By id: the label says what is being deleted and so varies with the hierarchy.
          check "#{dialog_id}-check_box", allow_label_click: true
          expect(page).to have_button "Delete permanently", disabled: false
          click_button "Delete permanently"
        end
      end

      def cancel_deletion
        within_dialog do
          click_button "Cancel"
        end
      end

      def expect_descendants_choice
        within_dialog do
          expect(page).to have_text "Delete all descendants too?"
        end
      end

      def expect_cross_project_warning(*projects)
        within_dialog do
          projects.each { |project| expect(page).to have_link project.name }
        end
      end

      # "Delete this work package and descendants" is preselected, so submitting opens the danger
      # dialog that previews and confirms the cascade.
      def confirm_descendants_deletion
        within_dialog { click_button "Delete" }
        descendants_dialog.confirm_deletion
      end

      def confirm_roots_only_deletion
        within_dialog do
          choose choice_label("self_only_label"), allow_label_click: true
          expect(page).to have_checked_field(choice_label("self_only_label"), visible: :all)
          click_button "Delete"
        end
      end

      private

      def descendants_dialog
        self.class.new(bulk_mode: @bulk_mode, dialog_id: "wp-delete-descendants-dialog")
      end

      def choice_label(key)
        scope = @bulk_mode ? "bulk_delete_dialog" : "delete_dialog"
        I18n.t("work_packages.#{scope}.descendants_choice.#{key}")
      end
    end
  end
end
