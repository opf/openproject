# frozen_string_literal: true

# -- copyright
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
# ++

require "support/components/common/modal"
require "support/components/autocompleter/ng_select_autocomplete_helpers"
module Components
  module Projects
    module ProjectLifeCycle
      class EditDialog < Components::Common::Modal
        def dialog_css_selector
          "dialog#edit-project-life-cycle-dialog"
        end

        def async_content_container_css_selector
          "#{dialog_css_selector} [data-test-selector='async-dialog-content']"
        end

        def within_dialog(&)
          within(dialog_css_selector, &)
        end

        def within_async_content(close_after_yield: false, &)
          within(async_content_container_css_selector, &)
          close if close_after_yield
        end

        def clear_dates(fields: %i(start_date finish_date))
          fields = Array(fields)

          if fields.include?(:start_date) && has_button?("start_date_clear_button")
            wait_for_turbo_stream(wait: 10) { click_button("start_date_clear_button") }
          end

          if fields.include?(:finish_date) && has_button?("finish_date_clear_button")
            wait_for_turbo_stream(wait: 10) { click_button("finish_date_clear_button") }
          end
        end

        def set_date_for(values:)
          dialog_selector = "##{Overviews::ProjectPhases::EditDialogComponent::DIALOG_ID}"
          datepicker = Components::RangeDatepicker.new(dialog_selector)

          values.each do |date|
            wait_for_turbo_stream(wait: 10) do
              datepicker.set_date(date.strftime("%Y-%m-%d"))
            end
          end
        end

        def activate_field(field_name)
          within_dialog do
            find_field(field_name).click
          end
          expect_input(field_name, active: true)
        end

        def close
          within_dialog do
            page.find(".close-button").click
          end
        end
        alias_method :close_via_icon, :close

        def close_via_button
          within_dialog do
            click_link_or_button "Cancel"
          end
        end

        def wait_for_form_preview_to_reload
          wait_for_network_idle
          expect(page).to have_no_css("form[aria-busy]")
        end

        def submit
          wait_for_turbo_stream(wait: 10) do
            within_dialog do
              page.find("[data-test-selector='save-project-life-cycle-button']").click
            end
          end
        end

        def expect_open
          expect(page).to have_css(dialog_css_selector)
        end

        def expect_closed
          expect(page).to have_no_css(dialog_css_selector)
        end

        def expect_async_content_loaded
          expect(page).to have_css(async_content_container_css_selector)
        end

        def expect_title(text)
          within_dialog do
            expect(page).to have_css("h1", text:)
          end
        end

        def expect_input(label, value: nil, disabled: false, active: false)
          field_options = { disabled: }
          if value
            field_options[:with] = value.respond_to?(:strftime) ? value.strftime("%Y-%m-%d") : value
          end
          field_options[:class] = "op-datepicker-modal--date-field_current" if active

          within_async_content do
            expect(page).to have_field(label, **field_options)
            # Note: This capybara matcher has a bug and it raises an error, if the
            # label, name and disabled flags are passed at once:
            #
            # TypeError: no implicit conversion of XPath::Expression into Integer (TypeError)
            #   expression_filter(:disabled) { |xpath, val| val ? xpath : xpath[~XPath.attr(:disabled)] }
            # from ~/.rbenv/versions/3.4.2/lib/ruby/gems/3.4.0/gems/capybara-3.40.0/lib/capybara/selector.rb:448:in 'String#[]'
            expect(page).to have_field(
              name: "project_phase[#{label.parameterize.underscore}]",
              **field_options
            )
          end
        end

        def expect_validation_message(field_name, text: nil, present: true)
          parent = find_field(field_name).ancestor("primer-text-field")
          if present
            expect(parent).to have_css('div[id^="validation"]', text:)
          else
            expect(parent).to have_no_css('div[id^="validation"]')
          end
        end

        def expect_no_validation_message(field_name)
          expect_validation_message(field_name, present: false)
        end
      end
    end
  end
end
