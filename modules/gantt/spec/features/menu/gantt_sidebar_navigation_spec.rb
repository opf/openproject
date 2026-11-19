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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Gantt sidebar navigation",
               :js do
  let(:user) { create(:admin) }
  let(:enabled_module_names) { %i[work_package_tracking gantt] }
  let(:project) { create(:project, enabled_module_names:) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:wp_timeline) { Pages::WorkPackagesTimeline.new(project) }
  let(:global_wp_timeline) { Pages::WorkPackagesTimeline.new }

  let!(:work_package) do
    create(:work_package,
           project:,
           start_date: Date.current,
           due_date: Date.current + 5.days)
  end

  before do
    login_as(user)
  end

  it "renders the gantt chart when navigating there within a project via the sidebar (#DREAM-1055)" do
    wp_table.visit!
    loading_indicator_saveguard

    find(".main-menu--arrow-left-to-project").click

    within ".main-menu" do
      gantt_link = find(:link, accessible_name: "Gantt charts")
      expect(gantt_link["data-turbo"]).to eq("false")

      gantt_link.click
    end

    loading_indicator_saveguard

    wp_timeline.expect_timeline!(open: true)
    wp_timeline.expect_work_package_listed work_package
  end

  it "renders the gantt chart when navigating there via the global sidebar (#DREAM-1055)" do
    visit home_path

    within ".main-menu" do
      gantt_link = find(:link, accessible_name: "Gantt charts")
      expect(gantt_link["data-turbo"]).to eq("false")

      gantt_link.click
    end

    loading_indicator_saveguard

    global_wp_timeline.expect_timeline!(open: true)
    global_wp_timeline.expect_work_package_listed work_package
  end

  it "renders the gantt chart when navigating there via the modules menu (#DREAM-1055)" do
    visit root_path

    within ".op-app-header" do
      page.find_test_selector("op-app-header--modules-menu-button").click
    end

    within "#op-app-header--modules-menu-list", visible: :all do
      click_on "Gantt charts", visible: :all
    end

    loading_indicator_saveguard

    global_wp_timeline.expect_timeline!(open: true)
    global_wp_timeline.expect_work_package_listed work_package
  end
end
