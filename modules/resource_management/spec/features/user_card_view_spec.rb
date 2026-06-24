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
require "support/components/autocompleter/ng_select_autocomplete_helpers"

RSpec.describe "User card view", :js do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management work_package_tracking]) }
  shared_let(:user) do
    create(:user, firstname: "Adam", lastname: "Admin",
                  member_with_permissions: { project => %i[view_resource_planners allocate_user_resources view_work_packages] })
  end
  shared_let(:member) do
    create(:user, firstname: "Mary", lastname: "Member",
                  member_with_permissions: { project => %i[view_resource_planners] })
  end
  shared_let(:resource_planner) do
    create(:resource_planner, project:, principal: user,
                              start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 31))
  end

  let(:query) { UserQuery.new(name: "People", project:, principal: user).tap(&:save!) }

  before { login_as user }

  def open_settings_dialog(view)
    find("a[href='#{edit_project_resource_planner_view_path(project, resource_planner, view)}']").click
    expect(page).to have_css("##{ResourcePlannerViews::EditDialogComponent::DIALOG_ID}")
  end

  describe "an automatically filtered view" do
    shared_let(:work_package) { create(:work_package, project:, subject: "Build the thing") }

    let(:view) do
      ResourceUserCard.create!(name: "People", parent: resource_planner, project:, principal: user, query:)
    end

    before do
      create(:resource_allocation, entity: work_package, principal: member)
      visit project_resource_planner_view_path(project, resource_planner, view)
    end

    it "renders every project member as a card by default" do
      expect(page).to have_test_selector("op-user-card", text: user.name)
      expect(page).to have_test_selector("op-user-card", text: member.name)
    end

    it "opens a user's utilization dialog with their allocations on click" do
      find_test_selector("op-user-card", text: member.name).click

      within("##{ResourcePlannerViews::UserCardList::UserAllocationsDialogComponent::DIALOG_ID}") do
        expect(page).to have_text(member.name)
        expect(page).to have_text("Build the thing")
      end
    end

    it "shows a blank message in the dialog for a user without allocations" do
      find_test_selector("op-user-card", text: user.name).click

      within("##{ResourcePlannerViews::UserCardList::UserAllocationsDialogComponent::DIALOG_ID}") do
        expect(page).to have_text(I18n.t("resource_management.user_allocations_dialog.blank"))
      end
    end

    it "updates the set of cards when filters change" do
      expect(page).to have_test_selector("op-user-card", text: user.name)
      expect(page).to have_test_selector("op-user-card", text: member.name)

      open_settings_dialog(view)

      filters = [{ name: { operator: "~", values: [member.firstname] } }].to_json

      within("##{ResourcePlannerViews::EditDialogComponent::DIALOG_ID}") do
        select "Name", from: "add_filter_select"
        within(".advanced-filters--filter[data-filter-name='name']") do
          fill_in "name_value", with: member.firstname
        end

        expect(page).to have_field("filters", type: :hidden, with: filters)
        click_on I18n.t(:button_save)
      end

      expect(page).to have_test_selector("op-user-card", text: member.name)
      expect(page).to have_no_test_selector("op-user-card", text: user.name)
    end
  end

  describe "switching the filter mode" do
    it "drops the filtered cards and becomes an empty manual list" do
      view = ResourceUserCard.create!(name: "People", parent: resource_planner, project:, principal: user, query:)
      visit project_resource_planner_view_path(project, resource_planner, view)
      expect(page).to have_test_selector("op-user-card", text: member.name)

      open_settings_dialog(view)
      within("##{ResourcePlannerViews::EditDialogComponent::DIALOG_ID}") do
        choose("view_filter_mode_manual", allow_label_click: true)
        click_on I18n.t(:button_save)
      end

      expect(page).to have_text(I18n.t("resource_management.user_card_list.blank.manual_description"))
      expect(page).to have_link(I18n.t("resource_management.user_card_list.subheader.resource"))
      expect(page).to have_no_test_selector("op-user-card")
    end

    it "discards the manually selected cards and shows the filtered list" do
      query.update!(manual_elements: true)
      view = ResourceUserCard.create!(name: "People", parent: resource_planner, project:, principal: user, query:)
      view.query.ordered_entities.create!(entity: member, position: 1)
      visit project_resource_planner_view_path(project, resource_planner, view)
      expect(page).to have_test_selector("op-user-card", text: member.name)
      expect(page).to have_no_test_selector("op-user-card", text: user.name)

      open_settings_dialog(view)
      within("##{ResourcePlannerViews::EditDialogComponent::DIALOG_ID}") do
        choose("view_filter_mode_automatic", allow_label_click: true)
        click_on I18n.t(:button_save)
      end

      expect(page).to have_test_selector("op-user-card", text: user.name)
      expect(page).to have_test_selector("op-user-card", text: member.name)
    end
  end

  describe "a manually picked view" do
    include Components::Autocompleter::NgSelectAutocompleteHelpers

    let(:view) do
      query.update!(manual_elements: true)
      ResourceUserCard.create!(name: "Special picks", parent: resource_planner, project:, principal: user, query:)
    end

    it "starts empty and adds a user through the autocompleter" do
      visit project_resource_planner_view_path(project, resource_planner, view)

      expect(page).to have_text(I18n.t("resource_management.user_card_list.blank.manual_description"))

      click_on I18n.t("resource_management.user_card_list.subheader.resource")

      within("##{ResourcePlannerViews::UserCardList::AddUserDialogComponent::DIALOG_ID}") do
        select_autocomplete(find("opce-user-autocompleter"), query: member.name, results_selector: "body")
        click_on I18n.t(:button_add)
      end

      expect(page).to have_test_selector("op-user-card", text: member.name)
    end

    it "removes a previously picked user via the remove action" do
      view.query.ordered_entities.create!(entity: member, position: 1)
      visit project_resource_planner_view_path(project, resource_planner, view)

      within(find_test_selector("op-user-card", text: member.name)) do
        accept_confirm { find("a[data-turbo-method='delete']").click }
      end

      expect(page).to have_no_test_selector("op-user-card", text: member.name)
      expect(page).to have_text(I18n.t("resource_management.user_card_list.blank.manual_description"))
    end
  end

  describe "the utilization bar" do
    # Friday 8h, Saturday-Sunday 0h, Monday 4h
    let(:planner) do
      create(:resource_planner, project:, principal: user,
                                start_date: Date.new(2026, 1, 9), end_date: Date.new(2026, 1, 12))
    end
    let(:view) { ResourceUserCard.create!(name: "People", parent: planner, project:, principal: user, query:) }

    before do
      create(:user_working_hours, user: member, valid_from: Date.new(2025, 1, 1), monday: 240)
      # 720 min booked Thu-Fri, but only Friday overlaps the window => capacity weighting puts 360 of it on each day.
      # The window's capacity is 720 (Fri 480 + the 4h Monday 240)
      create(:resource_allocation, principal: member, entity: create(:work_package, project:),
                                   allocated_time: 720, start_date: Date.new(2026, 1, 8), end_date: Date.new(2026, 1, 9))
      visit project_resource_planner_view_path(project, planner, view)
    end

    it "shows utilization prorated over the window's working time capacity" do
      # 360 booked (Friday only) / 720 capacity => 50%
      within(find_test_selector("op-user-card", text: member.name)) do
        expect(page).to have_text("50%")
      end
    end
  end
end
