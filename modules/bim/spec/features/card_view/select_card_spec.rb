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
require_relative "../../support/pages/ifc_models/show_default"

RSpec.describe "Selecting cards in the card view (regression #31962)", :js, with_config: { edition: "bim" } do
  let(:user) { create(:admin) }
  let(:project) { create(:project, enabled_module_names: %i[bim work_package_tracking]) }
  let(:wp_table) { Pages::IfcModels::ShowDefault.new(project) }
  let(:cards) { Pages::WorkPackageCards.new(project) }
  let!(:work_package1) { create(:work_package, project:) }
  let!(:work_package2) { create(:work_package, project:) }
  let!(:work_package3) { create(:work_package, project:) }

  before do
    work_package1
    work_package2
    work_package3

    login_as(user)
    wp_table.visit!
    wp_table.switch_view "Cards"
    cards.expect_work_package_listed work_package1, work_package2, work_package3
  end

  describe "selecting cards" do
    it "can select and deselect all cards" do
      # Select all
      cards.select_all_work_packages
      cards.expect_work_package_selected work_package1, true
      cards.expect_work_package_selected work_package2, true
      cards.expect_work_package_selected work_package3, true

      # Deselect all
      cards.deselect_all_work_packages
      cards.expect_work_package_selected work_package1, false
      cards.expect_work_package_selected work_package2, false
      cards.expect_work_package_selected work_package3, false
    end

    it "can select and deselect single cards" do
      # Select a card
      cards.select_work_package work_package1
      cards.expect_work_package_selected work_package1, true
      cards.expect_work_package_selected work_package2, false
      cards.expect_work_package_selected work_package3, false

      # Selecting another card changes the selection
      cards.select_work_package work_package2
      cards.expect_work_package_selected work_package1, false
      cards.expect_work_package_selected work_package2, true
      cards.expect_work_package_selected work_package3, false

      # Deselect a card
      cards.deselect_work_package work_package2
      cards.expect_work_package_selected work_package1, false
      cards.expect_work_package_selected work_package2, false
      cards.expect_work_package_selected work_package3, false
    end

    it "can select and deselect range of cards" do
      # Select the first WP
      cards.select_work_package work_package1
      cards.expect_work_package_selected work_package1, true
      cards.expect_work_package_selected work_package2, false
      cards.expect_work_package_selected work_package3, false

      # Select the third with Shift results in all WPs being selected
      cards.select_work_package_with_shift work_package3
      cards.expect_work_package_selected work_package1, true
      cards.expect_work_package_selected work_package2, true
      cards.expect_work_package_selected work_package3, true

      # The range can be changed
      cards.select_work_package_with_shift work_package2
      cards.expect_work_package_selected work_package1, true
      cards.expect_work_package_selected work_package2, true
      cards.expect_work_package_selected work_package3, false
    end
  end

  describe "opening" do
    it "the full screen view via double click" do
      cards.open_full_screen_by_doubleclick(work_package1)
      expect(page).to have_css(".work-packages--details--subject",
                               text: work_package1.subject)
    end

    it "the split screen of the selected WP" do
      cards.open_split_view_by_info_icon(work_package2)
      split_wp = Pages::SplitWorkPackage.new(work_package2)
      split_wp.expect_attributes Subject: work_package2.subject
    end

    it "can move between card details using info icon (Regression #33451)" do
      # move to first details
      split = cards.open_split_view_by_info_icon work_package1
      split.expect_subject

      # move to second details
      split2 = cards.open_split_view_by_info_icon work_package2
      split2.expect_subject
    end
  end
end
