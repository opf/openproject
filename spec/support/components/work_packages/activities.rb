#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
    class Activities
      include Capybara::DSL
      include Capybara::RSpecMatchers
      include RSpec::Matchers

      attr_reader :work_package

      def initialize(work_package)
        @work_package = work_package
        @container = ".work-package-details-activities-list"
      end

      def expect_wp_has_been_created_activity(work_package)
        within @container do
          expect(page).to have_content("created on #{work_package.created_at.strftime('%m/%d/%Y')}")
        end
      end

      def expect_notification_count(count)
        expect(page).to have_css('[data-test-selector="tab-counter-Activity"] span', text: count)
      end

      def expect_no_notification_badge
        expect(page).to have_no_css('[data-test-selector="tab-counter-Activity"] span')
      end

      def hover_action(journal_id, action)
        retry_block do
          # Focus type edit to expose buttons
          page
            .find("#activity-#{journal_id} .work-package-details-activities-activity-contents")
            .hover

          # Click the corresponding action button
          case action
          when :quote
            page.find("#activity-#{journal_id} .comments-icons .icon-quote").click
          end
        end
      end

      # helpers for new primerized activities

      def within_journal_entry(journal, &)
        page.within_test_selector("op-wp-journal-entry-#{journal.id}", &)
      end

      def expect_journal_changed_attribute(text:)
        expect(page).to have_css(".journal-detail-description", text:)
      end

      def expect_no_journal_changed_attribute(text: nil)
        expect(page).to have_no_css(".journal-detail-description", text:)
      end

      def expect_no_journal_notes(text: nil)
        expect(page).to have_no_css(".journal-notes-body", text:)
      end

      def expect_journal_details_header(text: nil)
        expect(page).to have_css(".journal-details-header", text:)
      end

      def expect_no_journal_details_header(text: nil)
        expect(page).to have_no_css(".journal-details-header", text:)
      end

      def expect_journal_notes_header(text: nil)
        expect(page).to have_css(".journal-notes-header", text:)
      end

      def expect_no_journal_notes_header(text: nil)
        expect(page).to have_no_css(".journal-notes-header", text:)
      end

      def expect_journal_notes(text: nil)
        expect(page).to have_css(".journal-notes-body", text:)
      end

      def add_comment(text: nil)
        # TODO: get rid of static sleep
        sleep 1 # otherwise the stimulus component is not mounted yet and the click does not work

        if page.has_css?("#open-work-package-journal-form")
          page.find_by_id("open-work-package-journal-form").click
        else
          expect(page).to have_css("#work-package-journal-form")
        end

        within("#work-package-journal-form") do
          FormFields::Primerized::EditorFormField.new("notes", selector: "#work-package-journal-form").set_value(text)
          page.find_test_selector("op-submit-work-package-journal-form").click
        end

        page.within_test_selector("op-wp-journals-container") do
          expect(page).to have_text(text)
        end
      end

      def get_all_comments_as_arrary
        page.all(".journal-notes-body").map(&:text)
      end

      def filter_journals(filter)
        page.find_test_selector("op-wp-journals-filter-menu").click

        case filter
        when :all
          page.find_test_selector("op-wp-journals-filter-show-all").click
        when :only_comments
          page.find_test_selector("op-wp-journals-filter-show-only-comments").click
        when :only_changes
          page.find_test_selector("op-wp-journals-filter-show-only-changes").click
        end

        sleep 1 # wait for the journals to be reloaded, TODO: get rid of static sleep
      end

      def set_journal_sorting(sorting)
        page.find_test_selector("op-wp-journals-sorting-menu").click

        case sorting
        when :asc
          page.find_test_selector("op-wp-journals-sorting-asc").click
        when :desc
          page.find_test_selector("op-wp-journals-sorting-desc").click
        end

        sleep 1 # wait for the journals to be reloaded, TODO: get rid of static sleep
      end
    end
  end
end
