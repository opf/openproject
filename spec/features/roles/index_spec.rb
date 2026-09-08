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

RSpec.describe "Roles index", :js do
  include Flash::Expectations

  current_user { create(:admin) }

  let!(:first_role) { create(:project_role, name: "Alpha") }
  let!(:second_role) { create(:project_role, name: "Beta") }

  def open_role_menu(role)
    within("#role-#{role.id}") do
      click_on accessible_name: I18n.t(:button_actions)
    end
  end

  def open_role_move_menu(role)
    open_role_menu(role)
    click_on I18n.t(:button_move)
  end

  def expect_move_directions(role, upwards:, downwards:)
    within("#role-#{role.id}") do
      [I18n.t(:label_sort_highest), I18n.t(:label_sort_higher)].each do |label|
        upwards ? expect(page).to(have_text(label)) : expect(page).to(have_no_text(label))
      end

      [I18n.t(:label_sort_lower), I18n.t(:label_sort_lowest)].each do |label|
        downwards ? expect(page).to(have_text(label)) : expect(page).to(have_no_text(label))
      end
    end
  end

  def role_names_in_order
    page.all("[role='rowheader']").map(&:text)
  end

  # Role's default scope eager-loads role_permissions, which duplicates rows under pluck.
  def reorderable_role_ids
    Role.visible.builtin(false).unscope(:includes).order(:position).pluck(:id)
  end

  it "shows the global flag" do
    global_role = create(:global_role, name: "Gamma")

    visit roles_path

    within("#role-#{global_role.id}") do
      expect(page).to have_css("[data-test-selector='role-global-checkmark']")
    end

    within("#role-#{first_role.id}") do
      expect(page).to have_no_css("[data-test-selector='role-global-checkmark']")
    end
  end

  it "moves a role through the action menu" do
    visit roles_path

    expect(role_names_in_order).to eq(%w[Alpha Beta])

    open_role_menu(second_role)
    click_on I18n.t(:button_move)
    click_on I18n.t(:label_sort_highest)

    expect(role_names_in_order).to eq(%w[Beta Alpha])

    wait_for { reorderable_role_ids }.to eq([second_role.id, first_role.id])

    refresh

    expect(role_names_in_order).to eq(%w[Beta Alpha])
  end

  # Selenium-driven: Pragmatic drag and drop needs real native drag events,
  # which Cuprite cannot reliably synthesize.
  it "reorders roles by dragging a row", :selenium do
    visit roles_path

    drag_role(first_role, after: second_role)

    expect(role_names_in_order).to eq(%w[Beta Alpha])

    wait_for { reorderable_role_ids }.to eq([second_role.id, first_role.id])

    refresh

    expect(role_names_in_order).to eq(%w[Beta Alpha])
  end

  it "does not offer a drag handle for builtin roles" do
    builtin_role = ProjectRole.non_member

    visit roles_path

    expect(page).to have_css("#role-#{first_role.id} .DragHandle")
    expect(page).to have_no_css("#role-#{builtin_role.id} .DragHandle")
  end

  it "only offers the move directions the role can actually move in" do
    last_role = create(:project_role, name: "Gamma")

    visit roles_path

    open_role_move_menu(first_role)
    expect_move_directions(first_role, upwards: false, downwards: true)

    refresh

    open_role_move_menu(second_role)
    expect_move_directions(second_role, upwards: true, downwards: true)

    refresh

    open_role_move_menu(last_role)
    expect_move_directions(last_role, upwards: true, downwards: false)
  end

  # The row that is last on arrival becomes movable-up only after it moves, and the menu
  # is never re-rendered, so availability has to be recomputed client-side on every open.
  it "recomputes the offered move directions after a move" do
    visit roles_path

    open_role_move_menu(second_role)
    click_on I18n.t(:label_sort_highest)

    expect(role_names_in_order).to eq(%w[Beta Alpha])

    open_role_move_menu(second_role)
    expect_move_directions(second_role, upwards: false, downwards: true)
  end

  it "does not offer moving a single reorderable role" do
    second_role.destroy

    visit roles_path

    open_role_menu(first_role)

    expect(page).to have_no_text(I18n.t(:button_move))
    expect(page).to have_text(I18n.t(:button_delete))
  end

  it "deletes a role through the action menu" do
    visit roles_path

    open_role_menu(first_role)
    accept_confirm { click_on I18n.t(:button_delete) }

    expect_and_dismiss_flash(message: I18n.t(:notice_successful_delete))

    expect(page).to have_no_css("#role-#{first_role.id}")
    expect(ProjectRole).not_to exist(id: first_role.id)
  end

  it "does not offer moving or deleting builtin roles" do
    builtin_role = ProjectRole.non_member

    visit roles_path

    open_role_menu(builtin_role)

    expect(page).to have_no_text(I18n.t(:button_move))
    expect(page).to have_no_text(I18n.t(:button_delete))
    expect(page).to have_text(I18n.t(:button_edit))
  end

  def drag_role(role, after:)
    handle = find("#role-#{role.id} .DragHandle")
    target = find("#role-#{after.id}")
    offset_y = (target.native.rect.height / 2) - [6, target.native.rect.height / 4].min

    perform_native_drag(source: handle, target:, offset_y: offset_y.round)

    # Assert Pragmatic DnD tore down its own honey-pot overlay, so a regression
    # leaving it stuck is caught here rather than as an unrelated click failure.
    expect(page).to have_no_css("[data-pdnd-honey-pot]", wait: 2, visible: :all)
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    retry
  end
end
