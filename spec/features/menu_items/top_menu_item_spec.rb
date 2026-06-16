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

RSpec.describe "Top menu items", :js do
  shared_let(:project) { create(:project, public: true) }
  let(:user) { create(:user) }
  let(:open_menu) { true }

  def has_menu_items?(*items)
    within ".op-app-header" do
      items.each do |item|
        expect(page).to have_link(item.label)
      end
      (all_items - items).each do |item|
        expect(page).to have_no_link(item.label)
      end
    end
  end

  def click_link_in_open_menu(title)
    within "#op-app-header--modules-menu-list" do
      expect(page).to have_no_css("[style~=overflow]")

      click_link(title)
    end
  end

  before do
    allow(User).to receive(:current).and_return user
    create(:anonymous_role, permissions: [:view_news])
    create(:non_member, permissions: [:view_news])

    if defined?(additional_before)
      additional_before.call
    end

    visit root_path
    wait_for_reload
    top_menu.click if open_menu
  end

  describe "Modules" do
    let!(:top_menu) { page.find_test_selector("op-app-header--modules-menu-button") }

    shared_let(:menu_link_item) { Struct.new(:label, :path) }

    shared_let(:project_item) { menu_link_item.new(I18n.t(:label_projects_menu), projects_path) }
    shared_let(:activity_item) { menu_link_item.new(I18n.t(:label_activity), activity_index_path) }
    shared_let(:work_packages_item) { menu_link_item.new(I18n.t(:label_work_package_plural), work_packages_path) }
    shared_let(:calendar_item) { menu_link_item.new(I18n.t(:label_calendar_plural), calendars_path) }
    shared_let(:team_planners_item) { menu_link_item.new(I18n.t("team_planner.label_team_planner_plural"), team_planners_path) }
    shared_let(:boards_item) { menu_link_item.new(I18n.t(:project_module_board_view), work_package_boards_path) }
    shared_let(:news_item) { menu_link_item.new(I18n.t(:label_news_plural), news_index_path) }
    shared_let(:reporting_item) { menu_link_item.new(I18n.t(:cost_reports_title), "/cost_reports") }
    shared_let(:meetings_item) { menu_link_item.new(I18n.t(:label_meeting_plural), "/meetings") }
    shared_let(:my_page_item) { menu_link_item.new(I18n.t("my_page.label"), my_page_path) }
    shared_let(:home_item) { menu_link_item.new(I18n.t(:label_home), home_path) }
    shared_let(:my_time_tracking_item) { menu_link_item.new(I18n.t(:label_my_time_tracking), "/my/time-tracking") }

    shared_let(:all_items) do
      [
        project_item,
        activity_item,
        work_packages_item,
        calendar_item,
        team_planners_item,
        boards_item,
        news_item,
        reporting_item,
        meetings_item,
        my_page_item,
        home_item,
        my_time_tracking_item
      ]
    end

    shared_examples "visits the global index page" do |item:|
      it "visits the #{item.label} page" do
        click_link_in_open_menu item.label
        expect(page).to have_current_path item.path
      end
    end

    context "as an admin" do
      let(:user) { create(:admin) }

      it "displays all items" do
        has_menu_items?(*all_items)
      end

      it "visits all module pages", :aggregate_failures, with_ee: %i[team_planner_view] do
        all_items.each do |item|
          click_link_in_open_menu item.label
          expect(page).to have_current_path(item.path)

          top_menu.click if open_menu
        end
      end
    end

    context "as a regular user" do
      it "only displays projects, activity, news, my page and home" do
        has_menu_items? project_item, activity_item, news_item, home_item, my_page_item
      end
    end

    context "as a user with permissions" do
      let(:additional_before) do
        -> { mock_permissions_for(user, &:allow_everything) }
      end

      it "displays all options" do
        has_menu_items?(*all_items)
      end
    end

    context "as an anonymous user" do
      let(:user) { create(:anonymous) }

      context "when login_required", with_settings: { login_required: true } do
        it "redirects to login" do
          expect(page).to have_current_path /login/
        end
      end

      context "when not login_required", with_settings: { login_required: false } do
        it "displays only projects, activity, news and home" do
          has_menu_items? project_item, activity_item, news_item, home_item
        end
      end
    end
  end
end
