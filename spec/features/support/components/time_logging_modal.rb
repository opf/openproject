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
  class TimeLoggingModal
    include Capybara::DSL
    include Capybara::RSpecMatchers
    include RSpec::Matchers
    include ::Components::Autocompleter::AutocompleteHelpers

    def is_visible(visible)
      if visible
        within modal_container do
          expect(page).to have_button(I18n.t("button_log_time"))
        end
      else
        expect(page).to have_no_css "dialog#time-entry-dialog"
      end
    end

    def change_hours(value)
      within modal_container do
        fill_in "time_entry_hours_display", with: value
      end
    end

    def submit
      wait_for_autocompleter_options_to_be_loaded
      within modal_container do
        click_on I18n.t("button_log_time")
      end
    end

    def cancel
      within modal_container do
        click_on I18n.t("button_cancel")
      end
    end

    def delete
      within modal_container do
        click_on I18n.t("button_delete")
      end
    end

    def has_field_with_value(field, value)
      within modal_container do
        expect(page).to have_field "time_entry_#{field}", with: value, visible: :all
      end
    end

    # TODO: Make this aware of more entities
    def expect_work_package(work_package)
      title = "#{work_package.type.name} ##{work_package.id} #{work_package.subject}"
      within modal_container do
        expect(page).to have_field("time_entry_entity_type", with: "WorkPackage", type: :hidden)
        expect(page).to have_css("opce-time-entries-work-package-autocompleter .ng-value", text: title, wait: 10)
      end
    end

    def expect_user(user)
      within modal_container do
        expect(page).to have_css("opce-user-autocompleter .ng-value", text: user.name, wait: 10)
      end
    end

    def shows_caption(caption)
      within modal_container do
        expect(page).to have_css(".FormControl-caption", text: caption)
      end
    end

    def requires_field(field, required: true)
      within modal_container do
        if required
          expect(page).to have_css "#time_entry_#{field}[aria-required=true]"
        else
          expect(page).to have_no_css "#time_entry_#{field}[aria-required=true]"
        end
      end
    end

    def trigger_field_change_event(field)
      modal_container.find("#time_entry_#{field}").trigger("change")
    end

    def shows_field(field, visible)
      within modal_container do
        if visible
          expect(page).to have_field "time_entry_#{field}"
        else
          expect(page).to have_no_field "time_entry_#{field}"
        end
      end
    end

    def field_has_error(field, error)
      within modal_container do
        expect(page).to have_css(".FormControl:has(label[for=time_entry_#{field}]) > .FormControl-inlineValidation", text: error)
      end
    end

    def update_time_field(field_name, hour:, minute:)
      built_time = browser_timezone.local(2025, 1, 1, hour, minute, 0)
      page.fill_in "time_entry_#{field_name}", with: built_time.iso8601
    end

    def update_field(field_name, value)
      if field_name.in?(%w[entity_id user_id activity_id])
        select_autocomplete modal_container.find("#time_entry_#{field_name}"),
                            query: value,
                            select_text: value,
                            results_selector: "#time-entry-dialog",
                            expected_value: value
      else
        within modal_container do
          fill_in "time_entry_#{field_name}", with: value
        end
      end
    end

    def perform_action(action)
      within modal_container do
        click_button action
      end
    end

    def activity_input_disabled_because_work_package_missing?(missing)
      if missing
        expect(modal_container).to have_field "time_entry_activity_id",
                                              visible: :all,
                                              disabled: true

        expect(modal_container).to have_css(".ng-placeholder", text: I18n.t("placeholder_activity_select_work_package_first"))
      else
        expect(modal_container).to have_field "time_entry_activity_id",
                                              visible: :all,
                                              disabled: false
      end
    end

    def has_hidden_work_package_field_for(work_package)
      expect(modal_container).to have_field "input#time_entry_entity_id",
                                            with: work_package.id,
                                            type: :hidden
    end

    private

    def browser_timezone
      return @browser_timezone if defined?(@browser_timezone)

      browser_tz_name = page.evaluate_script("Intl.DateTimeFormat().resolvedOptions().timeZone")
      @browser_timezone = ActiveSupport::TimeZone[browser_tz_name]
    end

    def modal_container
      page.find("dialog#time-entry-dialog", visible: :all)
    end
  end
end
