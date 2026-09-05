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

require "spec_helper"
require_relative "shared_context"

# Selenium-driven: Pragmatic drag and drop needs real native drag events,
# which Cuprite cannot reliably synthesize (see the backlogs DnD specs, the
# reference consumer for this drag helper style).
RSpec.describe "Reordering project attribute sections and fields", :js, :selenium do
  include_context "with seeded project custom fields"

  let(:cf_index_page) { Pages::Admin::Settings::ProjectCustomFields::Index.new }

  before do
    login_as(admin)
    cf_index_page.visit!
  end

  it "drags a field below another field within the same section, and it persists" do
    drag_field(boolean_project_custom_field, after: string_project_custom_field)

    expect_fields_in_order(string_project_custom_field, boolean_project_custom_field, integer_project_custom_field)

    cf_index_page.visit!

    expect_fields_in_order(string_project_custom_field, boolean_project_custom_field, integer_project_custom_field)
  end

  it "drags a field into another section, including an empty one, and it persists" do
    drag_field(user_project_custom_field, before: multi_list_project_custom_field)

    expect_no_field_in_section(section_for_select_fields, user_project_custom_field)
    expect_fields_in_order(user_project_custom_field, multi_list_project_custom_field)

    empty_section = create(:project_custom_field_section, name: "Empty section")
    cf_index_page.visit!

    # persisted across the reload
    expect_no_field_in_section(section_for_select_fields, user_project_custom_field)
    expect_fields_in_order(user_project_custom_field, multi_list_project_custom_field)

    drag_field(version_project_custom_field, into: empty_section)

    expect_no_field_in_section(section_for_select_fields, version_project_custom_field)
    expect_field_in_section(empty_section, version_project_custom_field)
    within_project_custom_field_section_container(empty_section) do
      expect(page).to have_no_css("[data-empty-list-item]")
    end

    cf_index_page.visit!

    expect_no_field_in_section(section_for_select_fields, user_project_custom_field)
    expect_no_field_in_section(section_for_select_fields, version_project_custom_field)
    expect_field_in_section(empty_section, version_project_custom_field)
    expect_fields_in_order(user_project_custom_field, multi_list_project_custom_field)
  end

  it "drags a section below another section, and it persists" do
    # Adjacent sections: input_fields (8 fields) sits at the top of a tall
    # page, so dragging it clear across would require a native pointer move
    # beyond the viewport. select_fields already sits right above
    # multi_select_fields, keeping the drag distance short regardless of
    # scroll position.
    drag_section(section_for_select_fields, after: section_for_multi_select_fields)

    expect_sections_in_order(section_for_input_fields, section_for_multi_select_fields, section_for_select_fields)

    cf_index_page.visit!

    expect_sections_in_order(section_for_input_fields, section_for_multi_select_fields, section_for_select_fields)
  end

  it "still reorders sections and fields via the kebab move menus" do
    perform_section_menu_action(section_for_multi_select_fields, "Move up")

    expect_sections_in_order(section_for_input_fields, section_for_multi_select_fields, section_for_select_fields)

    perform_field_menu_action(user_project_custom_field, "Move to top")

    expect_fields_in_order(user_project_custom_field, list_project_custom_field)

    cf_index_page.visit!

    expect_sections_in_order(section_for_input_fields, section_for_multi_select_fields, section_for_select_fields)
    expect_fields_in_order(user_project_custom_field, list_project_custom_field)
  end

  it "allows a second drag on a field whose section was morphed by the first drag" do
    drag_field(boolean_project_custom_field, after: string_project_custom_field)

    expect_fields_in_order(string_project_custom_field, boolean_project_custom_field, integer_project_custom_field)

    # string_project_custom_field's row was patched (not replaced) by the morph
    # that reconciled the first drag; drag it again to prove it is still wired.
    drag_field(string_project_custom_field, after: date_project_custom_field)

    expect_fields_in_order(date_project_custom_field, string_project_custom_field, text_project_custom_field)

    cf_index_page.visit!

    expect_fields_in_order(date_project_custom_field, string_project_custom_field, text_project_custom_field)
  end

  # helper methods:

  def within_project_custom_field_section_container(section, &)
    within_test_selector("project-custom-field-section-container-#{section.id}", &)
  end

  def within_project_custom_field_container(custom_field, &)
    within_test_selector("project-custom-field-container-#{custom_field.id}", &)
  end

  def within_project_custom_field_section_menu(section, &)
    within_project_custom_field_section_container(section) do
      page.find_test_selector("project-custom-field-section-action-menu").click
      within("anchored-position", &)
    end
  end

  def within_project_custom_field_menu(custom_field, &)
    within_project_custom_field_container(custom_field) do
      page.find_test_selector("project-custom-field-action-menu").click
      within("anchored-position", &)
    end
  end

  def perform_section_menu_action(section, action)
    within_project_custom_field_section_menu(section) do
      wait_for_turbo_stream { click_on(action) }
    end
  end

  def perform_field_menu_action(custom_field, action)
    within_project_custom_field_menu(custom_field) do
      wait_for_turbo_stream { click_on(action) }
    end
  end

  def field_row_selector(custom_field)
    "[data-sortable-lists--item-id-value='#{custom_field.id}'][data-sortable-lists--item-type-value='custom_field']"
  end

  def section_row_selector(section)
    "[data-sortable-lists--item-id-value='#{section.id}'][data-sortable-lists--item-type-value='section']"
  end

  def field_item(custom_field)
    find(field_row_selector(custom_field))
  end

  def section_item(section)
    find(section_row_selector(section))
  end

  # A section row nests its own field list (with its fields' handles), so a
  # plain descendant search inside a section's item element matches every
  # nested handle too. The item's own handle always renders in its header,
  # before any rows it nests, so it is reliably the first match.
  def drag_handle(item_element)
    item_element.first("[data-sortable-lists--item-target~='handle']")
  end

  def empty_section_drop_target(section)
    within_project_custom_field_section_container(section) do
      find("[data-empty-list-item]")
    end
  end

  def expect_fields_in_order(*custom_fields)
    expect(page).to have_css(custom_fields.map { |cf| field_row_selector(cf) }.join(" + "))
  end

  def expect_sections_in_order(*sections)
    expect(page).to have_css(sections.map { |s| section_row_selector(s) }.join(" + "))
  end

  def expect_field_in_section(section, custom_field)
    within_project_custom_field_section_container(section) do
      expect(page).to have_css(field_row_selector(custom_field))
    end
  end

  def expect_no_field_in_section(section, custom_field)
    within_project_custom_field_section_container(section) do
      expect(page).to have_no_css(field_row_selector(custom_field))
    end
  end

  # Drags a project custom field row via its drag handle. Exactly one of
  # before:, after: or into: (an empty section) must be given.
  #
  # Retries on a stale reference: a drop can trigger a Turbo morph mid-drag
  # bookkeeping (e.g. re-locating the target after a previous drag in the same
  # example), and this suite runs Selenium only, so the Selenium-specific
  # error is what actually surfaces here (unlike Cuprite-driven specs
  # elsewhere, which raise Capybara::Cuprite::ObsoleteNode instead).
  def drag_field(custom_field, before: nil, after: nil, into: nil)
    unless [before, after, into].compact.one?
      raise ArgumentError, "You must specify exactly one of before, after or into"
    end

    handle = drag_handle(field_item(custom_field))

    target_element, edge =
      if before
        [field_item(before), :top]
      elsif after
        [field_item(after), :bottom]
      else
        [empty_section_drop_target(into), nil]
      end

    wait_for_turbo_stream { drag_via_handle(handle:, target_element:, edge:) }
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    retry
  end

  def drag_section(section, before: nil, after: nil)
    unless [before, after].compact.one?
      raise ArgumentError, "You must specify exactly one of before or after"
    end

    handle = drag_handle(section_item(section))
    target_element, edge = before ? [section_item(before), :top] : [section_item(after), :bottom]

    wait_for_turbo_stream { drag_via_handle(handle:, target_element:, edge:) }
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    retry
  end

  def drag_via_handle(handle:, target_element:, edge: nil)
    offset_x, offset_y = selenium_target_offset(target_element.native.rect, edge:)
    perform_native_drag(source: handle, target: target_element, offset_x:, offset_y:)

    # Assert Pragmatic DnD tore down its own honey-pot overlay before we force
    # a cleanup, so a regression that leaves the overlay stuck is caught here
    # instead of being masked by the JS removal below.
    expect(page).to have_no_css("[data-pdnd-honey-pot]", wait: 2, visible: :all)
    clear_pragmatic_dnd_honey_pot
  end

  def selenium_target_offset(rect, edge:)
    offset = [6, rect.height / 4].min

    [
      0,
      case edge
      when :top
        offset - (rect.height / 2)
      when :bottom
        (rect.height / 2) - offset
      else
        0
      end
    ].map(&:round)
  end

  def clear_pragmatic_dnd_honey_pot
    page.execute_script(<<~JS)
      document
        .querySelectorAll('[data-pdnd-honey-pot]')
        .forEach((element) => element.remove());
    JS
  end
end
