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

require "support/pages/page"

module Pages
  class AbstractWorkPackage < Page
    attr_reader :project, :work_package

    def initialize(work_package, project = nil)
      @work_package = work_package
      @project = project
    end

    def create_page?
      is_a?(AbstractWorkPackageCreate)
    end

    def visit_tab!(tab)
      visit path(tab)
    end

    def switch_to_tab(tab:)
      find(".op-tab-row--link", text: tab.upcase).click
    end

    def expect_tab(tab)
      expect(page).to have_css(".op-tab-row--link_selected", text: tab.to_s.upcase)
    end

    def expect_no_tab(tab)
      expect(page).to have_no_css(".op-tab-row--link", text: tab.to_s.upcase)
    end

    def within_active_tab(&)
      within(".work-packages-full-view--split-right .work-packages--panel-inner", &)
    end

    def edit_field(attribute)
      work_package_field(attribute)
    end

    def custom_edit_field(custom_field)
      edit_field(custom_field.attribute_name(:camel_case)).tap do |field|
        if custom_field.list?
          field.field_type = "create-autocompleter"
        end
      end
    end

    def container
      raise NotImplementedError
    end

    def expect_comment(**args)
      subselector = args.delete(:subselector)

      retry_block do
        unless page.has_selector?(".user-comment .message #{subselector}".strip, **args)
          raise "Failed to find comment with #{args.inspect}. Retrying."
        end
      end
    end

    def expect_hidden_field(attribute)
      page.within(container) do
        expect(page).to have_no_css(".inline-edit--display-field.#{attribute}")
      end
    end

    def expect_subject
      page.within(container) do
        expect(page).to have_content(work_package.subject)
      end
    end

    def open_in_split_view
      find_by_id("work-packages-details-view-button").click
    end

    def ensure_page_loaded
      expect_angular_frontend_initialized
      expect(page).to have_css(".op-user-activity--user-name",
                               text: work_package.journals.last.user.name,
                               minimum: 1,
                               wait: 10)
    end

    def disable_ajax_requests
      page.execute_script(
        "var p=window.XMLHttpRequest.prototype; p.open=p.send=p.setRequestHeader=function(){};"
      )
    end

    def expect_group(name, &)
      expect(page).to have_css(".attributes-group--header-text", text: name.upcase)
      if block_given?
        page.within(".attributes-group[data-group-name='#{name}']", &)
      end
    end

    def expect_no_group(name)
      expect(page).to have_no_css(".attributes-group--header-text", text: name.upcase)
    end

    def expect_attributes(attribute_expectations)
      attribute_expectations.each do |label_name, value|
        label = label_name.to_s
        if label == "status"
          expect(page).to have_css("[data-test-selector='op-wp-status-button'] .button", text: value)
        else
          expect(page).to have_css(".inline-edit--container.#{label.camelize(:lower)}", text: value)
        end
      end
    end

    def expect_no_attribute(label)
      expect(page).to have_no_css(".inline-edit--container.#{label.downcase}")
    end

    alias :expect_attribute_hidden :expect_no_attribute

    def expect_activity(user, number: nil)
      container = "#work-package-activites-container"
      container += " #activity-#{number}" if number

      expect(page).to have_css("#{container} .op-user-activity--user-line", text: user.name)
    end

    def expect_activity_message(message)
      expect(page).to have_css(".work-package-details-activities-messages .message",
                               text: message)
    end

    def expect_no_parent
      visit_tab!("relations")

      expect(page).to have_no_css('[data-test-selector="op-wp-breadcrumb-parent"]')
    end

    def expect_zen_mode
      expect(page).to have_css(".zen-mode")
      expect(page).to have_css("#main-menu", visible: :hidden)
      expect(page).to have_css(".op-app-header", visible: :hidden)
    end

    def expect_no_zen_mode
      expect(page).to have_no_css(".zen-mode")
      expect(page).to have_css("#main-menu")
      expect(page).to have_css(".op-app-header")
    end

    def expect_custom_action(name)
      expect(page)
        .to have_css(".custom-action", text: name)
    end

    def expect_custom_action_disabled(name)
      expect(page)
        .to have_css(".custom-action [disabled]", text: name)
    end

    def expect_no_custom_action(name)
      expect(page)
        .to have_no_css(".custom-action", text: name)
    end

    def expect_custom_action_order(*names)
      within(".custom-actions") do
        names.each_cons(2) do |earlier, later|
          body.index(earlier) < body.index(later)
        end
      end
    end

    def update_attributes(save: !create_page?, **key_value_map)
      set_attributes(key_value_map, save:)
    end

    def set_attributes(key_value_map, save: !create_page?)
      key_value_map.each_with_index.map do |(key, value), index|
        field = work_package_field(key)
        field.update(value, save:)
        if save && (index != key_value_map.length - 1)
          ensure_no_conflicting_modifications
        end
      end
    end

    def set_progress_attributes(key_value_map, save_intermediate_updates: true, save: !create_page?)
      key_value_map.each_with_index.map do |(key, value)|
        field = work_package_field(key)
        field.update(value, save: save_intermediate_updates)
      end

      ensure_no_conflicting_modifications if save
    end

    def work_package_field(key)
      case key
      when /customField(\d+)$/
        work_package_custom_field(key, $1)
      when :date, :startDate, :dueDate, :combinedDate
        DateEditField.new container, key, is_milestone: work_package&.milestone?
      when :estimatedTime, :remainingTime, :percentageDone, :statusWithinProgressModal
        ProgressEditField.new container, key, create_form: create_page?
      when :description
        TextEditorField.new container, key
        # The AbstractWorkPackageCreate pages do not require a special WorkPackageStatusField,
        # because the status field on the create pages is a simple EditField.
      when :status
        if create_page?
          EditField.new container, key, create_form: true
        else
          WorkPackageStatusField.new container
        end
      else
        EditField.new container, key, create_form: create_page?
      end
    end

    def work_package_custom_field(key, id)
      cf = CustomField.find id

      if cf.field_format == "text"
        TextEditorField.new container, key
      else
        EditField.new container, key
      end
    end

    def add_child
      visit_tab!("relations")

      page.find(".wp-inline-create--add-link",
                text: I18n.t("js.relation_buttons.add_new_child")).click

      create_page(parent_work_package: work_package)
    end

    def visit_copy!
      page = create_page(original_work_package: work_package)
      page.visit!

      page
    end

    def click_custom_action(name, expect_success: true)
      page.within(".custom-actions") do
        click_button(name)
      end

      if expect_success
        expect_and_dismiss_toaster message: "Successful update"
        wait_for_network_idle
      end
    end

    def trigger_edit_mode
      page.click_button(I18n.t("js.button_edit"))
    end

    def trigger_edit_comment
      add_comment_container.find(".work-package-comment").click
    end

    def update_comment(comment)
      editor = ::Components::WysiwygEditor.new ".work-packages--activity--add-comment"
      editor.click_and_type_slowly comment
    end

    def save_comment
      label = "Comment: Save"
      add_comment_container.find(:xpath, "//button[@title='#{label}']").click
    end

    def save!
      page.click_button(I18n.t("js.button_save"))
    end

    def add_comment_container
      find(".work-packages--activity--add-comment")
    end

    def click_add_wp_button
      find(".add-work-package:not([disabled])", text: "Work package").click
    end

    def click_create_wp_button(type)
      find(".add-work-package:not([disabled])", text: "Create").click

      find("#types-context-menu .menu-item", text: type.name.upcase, wait: 10).click
    end

    def subject_field
      expect(page).to have_css(".inline-edit--container.subject input", wait: 10)
      find(".inline-edit--container.subject input")
    end

    def go_back
      find(".work-packages-back-button").click
    end

    def mark_notifications_as_read
      find('[data-test-selector="mark-notification-read-button"]').click
    end

    private

    def create_page(_args)
      raise NotImplementedError
    end

    def ensure_no_conflicting_modifications
      expect_toast(message: "Successful update")
      dismiss_toaster!
      expect_no_toaster(message: "Successful update")
    end
  end
end
