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

# Guards the trailing-stem trim in
# app/components/work_packages/activities_tab/journals/item_component/details.sass
# (the `:has(.empty-line)` last-child rule). If this fails, that CSS rule is the
# thing to look at.
RSpec.describe "Work package activity comment stem", :js, :with_cuprite do
  current_user { admin }

  let(:project) { create(:project) }
  let(:admin) { create(:admin) }
  let(:work_package) { create(:work_package, project:, author: admin) }

  let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }
  let(:activity_tab) { Components::WorkPackages::Activities.new(work_package) }

  # In the comments-only view every entry renders a trailing empty-line spacer,
  # so the stem trimming has to single out just the bottom one.
  let!(:oldest_comment) do
    create(:work_package_journal, user: admin, notes: "Oldest comment", journable: work_package, version: 2)
  end
  let!(:newest_comment) do
    create(:work_package_journal, user: admin, notes: "Newest comment", journable: work_package, version: 3)
  end

  let(:details_container) do
    "work-packages-activities-tab-journals-item-component-details--journal-details-container"
  end

  before do
    work_package.journals.first.update!(user: admin)
    wp_page.visit!
    wp_page.wait_for_activity_tab
  end

  it "trims only the final comment's trailing stem when sorted descending" do
    activity_tab.set_journal_sorting(:desc)
    activity_tab.filter_journals(:only_comments)

    # Bottom entry: its stem is trimmed, but a condensed breather is kept below it.
    activity_tab.within_journal_entry(oldest_comment) do
      container = find(".#{details_container}")
      expect(left_border_width(container)).to eq("0px")
      expect(bottom_padding(container)).not_to eq("0px")
    end

    # The entry above keeps its stem so the timeline stays connected.
    activity_tab.within_journal_entry(newest_comment) do
      expect(left_border_width(find(".#{details_container}"))).not_to eq("0px")
    end

    # Ascending order has no dangling bottom node, so nothing is trimmed.
    activity_tab.set_journal_sorting(:asc, default_filter: :only_comments)

    activity_tab.within_journal_entry(oldest_comment) do
      expect(left_border_width(find(".#{details_container}"))).not_to eq("0px")
    end
  end

  def left_border_width(node)
    computed_style(node, "border-left-width")
  end

  def bottom_padding(node)
    computed_style(node, "padding-bottom")
  end

  def computed_style(node, property)
    SelectorHelpers.get_pseudo_class_property(page, node, "", property)
  end
end
