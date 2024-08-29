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

    attr_reader :activity_field,
                :comment_field,
                :hours_field,
                :spent_on_field,
                :work_package_field,
                :user_field

    def initialize
      @activity_field = EditField.new(page, "activity")
      @comment_field = EditField.new(page, "comment")
      @hours_field = EditField.new(page, "hours")
      @spent_on_field = EditField.new(page, "spentOn")
      @work_package_field = EditField.new(page, "workPackage")
      @user_field = EditField.new(page, "user")
    end

    def is_visible(visible)
      if visible
        within modal_container do
          expect(page)
            .to have_text(I18n.t("js.button_log_time"))
        end
      else
        expect(page).to have_no_css ".spot-modal"
      end
    end

    def has_field_with_value(field, value)
      within modal_container do
        expect(page).to have_field field_identifier(field), with: value, visible: :all
      end
    end

    def expect_work_package(subject)
      within modal_container do
        expect(page).to have_css(".ng-value", text: subject, wait: 10)
      end
    end

    def shows_field(field, visible)
      within modal_container do
        if visible
          expect(page).to have_css "##{field_identifier(field)}"
        else
          expect(page).to have_no_css "##{field_identifier(field)}"
        end
      end
    end

    def update_field(field_name, value)
      field = field_object field_name
      if field_name == "user"
        field.unset_value
        field.autocomplete value
      else
        field.input_element.click
        field.set_value value
      end
    end

    def update_work_package_field(value, recent = false)
      work_package_field.input_element.click

      if recent
        within(".ng-dropdown-header") do
          click_link(I18n.t("js.label_recent"))
        end
      end

      work_package_field.set_value(value)
    end

    def perform_action(action)
      within modal_container do
        click_button action
      end
    end

    def work_package_is_missing(missing)
      if missing
        expect(page)
          .to have_content(I18n.t("js.time_entry.work_package_required"))
      else
        expect(page)
          .to have_no_content(I18n.t("js.time_entry.work_package_required"))
      end
    end

    def field_identifier(field_name)
      case field_name
      when "spent_on"
        "wp-new-inline-edit--field-spentOn"
      when "work_package"
        "wp-new-inline-edit--field-workPackage"
      when "user"
        "wp-new-inline-edit--field-user"
      end
    end

    private

    def field_object(field_name)
      send(:"#{field_name}_field")
    end

    def modal_container
      page.find(".spot-modal")
    end
  end
end
