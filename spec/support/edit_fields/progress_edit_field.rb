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

require_relative "edit_field"

class ProgressEditField < EditField
  MODAL_SELECTOR = "#work_package_progress_modal"
  FIELD_NAME_MAP = {
    "estimatedTime" => :estimated_hours,
    "remainingTime" => :remaining_hours,
    "percentageDone" => :done_ratio,
    "statusWithinProgressModal" => :status_id
  }.freeze
  HUMAN_FIELD_NAME_MAP = {
    "estimatedTime" => "work",
    "remainingTime" => "remaining work",
    "percentageDone" => "% complete",
    "statusWithinProgressModal" => "status"
  }.freeze

  def initialize(context,
                 property_name,
                 selector: nil,
                 create_form: false)
    super

    @field_name = "work_package_#{FIELD_NAME_MAP.fetch(@property_name)}"
    @human_field_name = HUMAN_FIELD_NAME_MAP.fetch(@property_name)
    @trigger_selector = "input[id$=inline-edit--field-#{@property_name}]"
  end

  def visible_on_create_form?
    false
  end

  def update(value, save: true, expect_failure: false)
    super
  end

  def reactivate!(expect_open: true)
    retry_block(args: { tries: 2 }) do
      SeleniumHubWaiter.wait unless using_cuprite?
      scroll_to_and_click(display_element)
      SeleniumHubWaiter.wait unless using_cuprite?

      if expect_open && !active?
        raise "Expected field for attribute '#{property_name}' to be active."
      end

      self
    end
  end

  def active?
    page.has_selector?(MODAL_SELECTOR, wait: 1)
  end

  def clear
    super(with_backspace: true)
  end

  def set_value(value)
    if value == ""
      clear
    else
      page.fill_in field_name, with: value
    end
    wait_for_preview_to_complete
  end

  def focus
    return if focused?

    input_element.click
    wait_for_preview_to_complete
  end

  # Wait for the popover preview to be refreshed.
  # Preview occurs on field blur or change.
  def wait_for_preview_to_complete
    sleep 0.110 # the preview on popover has a debounce of 100ms
    if using_cuprite?
      wait_for_network_idle # Wait for preview to finish
    end
  end

  def input_element
    modal_element.find_field(field_name)
  end

  def input_caption_element
    input_element["aria-describedby"]
      .split
      .find { _1.start_with?("caption-") }
      &.then { |caption_id| find(id: caption_id) }
  end

  def trigger_element
    within @context do
      page.find(@trigger_selector)
    end
  end

  def save!
    submit_by_enter
  end

  def submit_by_enter
    input_element.native.send_keys :return
  end

  def submit_by_clicking_save
    within modal_element do
      click_on("Save")
    end
  end

  def close!
    page.find("[data-test-selector='op-progress-modal--close-icon']").click
  end

  def expect_active!
    expect(page).to have_css(MODAL_SELECTOR)
  end

  def expect_inactive!
    expect(page).to have_no_css(MODAL_SELECTOR)
  end

  # The selector for create contexts varies from that
  # of update contexts where the work package already
  # exists.
  def display_selector
    if create_form?
      ".inline-edit--active-field"
    else
      super
    end
  end

  # Checks if the modal field is in focus.
  # It compares the active element in the page (the element in focus) with the input element of the modal.
  # If they are the same, it means the modal field is in focus.
  # @return [Boolean] true if the modal field is in focus, false otherwise.
  def expect_modal_field_in_focus
    expect(focused?).to be(true)
  end

  def focused?
    input_element == page.evaluate_script("document.activeElement")
  end

  # Checks if the cursor is at the end of the input in the modal field.
  # It compares the cursor position (selectionStart) with the length of the value in the input field.
  # If they are the same, it means the cursor is at the end of the input.
  # @return [Boolean] true if the cursor is at the end of the input, false otherwise.
  def expect_cursor_at_end_of_input
    expect(cursor_at_end_of_input?).to be(true)
  end

  def cursor_at_end_of_input?
    input_element.evaluate_script("this.selectionStart == this.value.length;")
  end

  def expect_trigger_field_disabled
    expect(trigger_element).to be_disabled
  end

  def expect_modal_field_disabled
    expect(page).to have_field(@field_name, disabled: true)
  end

  def expect_read_only_modal_field
    expect(input_element).to be_readonly
  end

  def expect_modal_field_value(value, disabled: false, readonly: false)
    within modal_element do
      if @property_name == "percentageDone" && value.to_s == "-"
        expect(page).to have_field(field_name, readonly:, placeholder: value.to_s)
      elsif @property_name == "statusWithinProgressModal"
        if value == :empty_without_any_options
          expect(page).to have_select(field_name, disabled:, options: [])
        else
          expect(page).to have_select(field_name, disabled:, with_selected: value.to_s)
        end
      else
        expect(page).to have_field(field_name, disabled:, readonly:, with: value.to_s)
      end
    end
  end

  def expect_caption(expected_caption)
    if expected_caption.nil?
      expect(input_caption_element).to be_nil, "Expected no caption for #{@human_field_name} field, " \
                                               "got \"#{input_caption_element&.text}\""
    else
      expect(input_caption_element).to have_text(expected_caption)
    end
  end

  def expect_select_field_with_options(*expected_options)
    within modal_element do
      expect(page).to have_select(field_name, with_options: expected_options)
    end
  end

  def expect_select_field_with_no_options(*unexpected_options)
    within modal_element do
      expect(page).to have_no_select(field_name,
                                     with_options: unexpected_options,
                                     wait: 0)
    end
  end

  # to be removed in 15.0 with :percent_complete_edition feature flag removal
  def expect_migration_warning_banner(should_render: true)
    within modal_element do
      if should_render
        expect(page)
          .to have_text(I18n.t("work_package.progress.modal.migration_warning_text"))
      else
        expect(page)
          .to have_no_text(I18n.t("work_package.progress.modal.migration_warning_text"))
      end
    end
  end

  private

  attr_reader :field_name

  def modal_element
    page.find(MODAL_SELECTOR)
  end
end
