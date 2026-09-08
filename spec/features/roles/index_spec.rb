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

    expect(second_role.position).to be > first_role.position

    open_role_menu(second_role)
    click_on I18n.t(:button_move)
    click_on I18n.t(:label_sort_highest)

    expect_and_dismiss_flash(message: I18n.t(:notice_successful_update))

    expect(second_role.reload.position).to be < first_role.reload.position
  end

  it "only offers the move directions the role can actually move in" do
    visit roles_path

    open_role_menu(first_role)
    click_on I18n.t(:button_move)

    expect(page).to have_no_text(I18n.t(:label_sort_highest))
    expect(page).to have_no_text(I18n.t(:label_sort_higher))
    expect(page).to have_text(I18n.t(:label_sort_lower))
    expect(page).to have_text(I18n.t(:label_sort_lowest))
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
end
