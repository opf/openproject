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

require "rails_helper"

RSpec.describe Backlogs::InboxComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:admin) }
  let(:work_packages) { [] }
  let(:wp_scope) { WorkPackage.where(id: work_packages.map(&:id)).order(:position) }
  let(:show_all_backlog) { false }

  current_user { user }

  subject(:component) do
    described_class.new(
      work_packages: wp_scope,
      project:,
      current_user: user
    )
  end

  def render_component
    vc_test_controller.params[:all] = "1" if show_all_backlog

    render_inline component
  end

  before { render_component }

  describe "container" do
    it "renders a Primer::Beta::BorderBox with the inbox DOM id" do
      expect(page).to have_css(".Box#inbox_project_#{project.id}")
    end

    it "wires drop-target data attributes for the inbox" do
      expect(page).to have_css(".Box#inbox_project_#{project.id}") do |box|
        expect(box["data-sortable-lists-target"]).to eq("list")
        expect(box["data-sortable-lists-list-type"]).to eq("inbox")
        expect(box["data-sortable-lists-list-id"]).to be_nil
      end
    end

    it "announces dynamic empty-state updates" do
      expect(page).to have_role(:status, aria: { live: "polite" })
    end
  end

  describe "header" do
    let(:work_packages) do
      [
        create(:work_package, subject: "First item", project:, story_points: 2, position: 1),
        create(:work_package, subject: "Second item", project:, story_points: 4, position: 2)
      ]
    end

    it "renders the inbox title" do
      expect(page).to have_heading "Inbox", level: 4
      expect(page).to have_css("h4.f4", text: "Inbox")
    end

    it "renders the work-package count" do
      expect(page).to have_css(
        ".Counter",
        text: "2",
        aria: { label: I18n.t(:label_x_items, count: 2) }
      )
    end
  end

  describe "empty state" do
    let(:work_packages) { [] }

    it "shows the blankslate heading and description" do
      expect(page).to have_css("h4", text: "Backlog inbox is empty")
      expect(page).to have_text("All open work packages in this project will automatically appear here.")
    end
  end

  describe "with work packages" do
    let(:work_packages) do
      [
        create(:work_package, subject: "First item", project:, story_points: 2, position: 1),
        create(:work_package, subject: "Second item", project:, story_points: 4, position: 2)
      ]
    end

    it "renders a row for each work package", :aggregate_failures do
      expect(page).to have_css(".Box-row", count: 2)

      # renders the subject of each work package
      expect(page).to have_text("First item")
      expect(page).to have_text("Second item")

      # does not show the blankslate
      expect(page).to have_no_css("h4", text: "Backlog inbox is empty")
    end

    it "renders story points on each work package card" do
      expect(page).to have_css("span", text: "2", aria: { hidden: true })
      expect(page).to have_css(".sr-only", text: "2 story points")
      expect(page).to have_css("span", text: "4", aria: { hidden: true })
      expect(page).to have_css(".sr-only", text: "4 story points")
    end
  end

  describe "pagination" do
    # The inbox derives tail = max(truncate_middle / 5, 1) and the threshold to
    # truncate as truncate_middle + tail*2.
    let(:truncate_middle) { described_class::TRUNCATE_MIDDLE }
    let(:tail_size) { [truncate_middle / 5, 1].max }
    let(:threshold) { truncate_middle + (tail_size * 2) }
    let(:show_more_id) { "inbox_project_#{project.id}_show_more" }

    context "when work packages do not exceed the threshold" do
      let(:work_packages) { create_list(:work_package, threshold, project:) }

      it "renders all items without pagination" do
        expect(page).to have_css(".Box-row", count: threshold)
        expect(page).to have_no_css("##{show_more_id}")
      end
    end

    context "when work packages exceed the threshold" do
      let(:total) { threshold + 8 }
      let(:middle_count) { total - truncate_middle - tail_size }
      let(:work_packages) { create_list(:work_package, total, project:) }

      it "renders only the first page and last page items (not all)" do
        expect(page).to have_css(".Box-row", count: truncate_middle + tail_size + 1) # +1 for "show more" row
        expect(page).to have_css("##{show_more_id}")
        expect(page).to have_text("Show #{middle_count} more items")
      end

      it "renders the full work-package count in the header" do
        expect(page).to have_css(
          ".Counter",
          text: total.to_s,
          aria: { label: I18n.t(:label_x_items, count: total) }
        )
      end

      it "renders show-more targeting the full backlog turbo frame with all=1" do
        show_link = page.find("##{show_more_id}")
        expect(show_link[:href]).to include("all=1")
        expect(show_link["data-turbo-frame"]).to eq("backlogs_container")
      end

      it "renders the show-more row with the previous item id" do
        last_omitted = work_packages.sort_by(&:position)[-(tail_size + 1)]

        expect(page).to have_css("[data-sortable-lists-prev-item-id='#{last_omitted.id}']")
      end
    end

    context "when show_all_backlog is true and work packages exceed threshold" do
      let(:show_all_backlog) { true }
      let(:total) { threshold + 3 }
      let(:work_packages) { create_list(:work_package, total, project:) }

      it "renders all items without pagination" do
        expect(page).to have_css(".Box-row", count: total)
        expect(page).to have_no_css("##{show_more_id}")
      end
    end
  end
end
