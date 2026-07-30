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

RSpec.describe Backlogs::SprintReports::Widgets::WorkPackageOverview, type: :component do
  let(:project) { build_stubbed(:project) }
  let(:sprint) { build_stubbed(:sprint, project:, start_date: 1.week.ago.to_date, finish_date: 1.week.from_now.to_date) }

  subject(:rendered_component) { render_inline(described_class.new(sprint, project)) }

  context "when the sprint has no date range set" do
    let(:sprint) { build_stubbed(:sprint, project:, start_date: nil, finish_date: nil) }

    it "renders no breakdown blocks" do
      expect(rendered_component).to have_no_css(".op-wp-overview--blocks")
    end
  end

  context "when the sprint has a date range set" do
    let(:breakdown) { instance_double(SprintWorkPackageBreakdown) }
    let(:planned) do
      SprintWorkPackageBreakdown::Block.new(work_package_count: 5, story_points: 13, from_date: sprint.start_date)
    end
    let(:changed) do
      SprintWorkPackageBreakdown::Block.new(work_package_count: 2, story_points: 3, from_date: sprint.start_date,
                                            to_date: Time.zone.today)
    end
    let(:completed) do
      SprintWorkPackageBreakdown::Block.new(work_package_count: 3, story_points: 8, from_date: Time.zone.today)
    end
    let(:unfinished) do
      SprintWorkPackageBreakdown::Block.new(work_package_count: 2, story_points: 5, from_date: Time.zone.today)
    end

    before do
      allow(SprintWorkPackageBreakdown).to receive(:new).with(sprint:, project:).and_return(breakdown)
      allow(breakdown).to receive_messages(
        initially_planned: planned,
        changed_after_start: changed,
        completed:,
        unfinished:,
        reference_start: sprint.start_date,
        reference_finish: Time.zone.today,
        done_status_ids: [1, 2]
      )
    end

    it "renders a heading, count and story points for each block" do
      expect(rendered_component).to have_css(".op-wp-overview--blocks")
      expect(rendered_component).to have_text("Initially planned")
      expect(rendered_component).to have_text("Changed after start")
      expect(rendered_component).to have_text("Completed")
      expect(rendered_component).to have_text("Unfinished")
      expect(rendered_component).to have_text("5")
      expect(rendered_component).to have_text("13 story points")
      expect(rendered_component).to have_text("Show all", count: 4)
    end

    it "colors the completed count green and the unfinished count red" do
      expect(rendered_component).to have_css(".color-fg-success", text: "3")
      expect(rendered_component).to have_css(".color-fg-danger", text: "2")
    end

    it "links each block's 'Show all' to the work packages table filtered to the sprint" do
      query_props = rendered_component.css("a", text: "Show all").map do |link|
        JSON.parse(CGI.parse(URI.parse(link["href"]).query)["query_props"].first)
      end

      expect(query_props).to all(include("f" => include(include("n" => "sprintId"))))
      expect(query_props).to all(include("ts"))
    end
  end
end
