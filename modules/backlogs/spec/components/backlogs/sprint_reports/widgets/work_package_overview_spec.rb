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
  let(:sprint) do
    build_stubbed(:sprint, :active, project:,
                                    start_date: 1.week.ago.to_date,
                                    finish_date: 1.week.from_now.to_date,
                                    started_at: 1.week.ago)
  end

  subject(:rendered_component) { render_inline(described_class.new(sprint, project)) }

  context "when the sprint has started" do
    current_user { build_stubbed(:user) }

    let(:breakdown) { instance_double(SprintWorkPackageBreakdown) }
    let(:planned) do
      SprintWorkPackageBreakdown::Block.new(work_package_count: 5, story_points: 13, estimated_hours: 20)
    end
    let(:changed) do
      SprintWorkPackageBreakdown::ChangeBlock.new(added_count: 4, removed_count: 1, added_story_points: 6,
                                                  removed_story_points: 2, added_estimated_hours: 10,
                                                  removed_estimated_hours: 4)
    end
    let(:completed) do
      SprintWorkPackageBreakdown::Block.new(work_package_count: 3, story_points: 8, estimated_hours: 12)
    end
    let(:unfinished) do
      SprintWorkPackageBreakdown::Block.new(work_package_count: 2, story_points: 5, estimated_hours: 28)
    end

    before do
      mock_permissions_for(current_user) { |mock| mock.allow_in_project(:view_sprints, project:) }

      allow(SprintWorkPackageBreakdown).to receive(:new).with(sprint:, project:).and_return(breakdown)
      allow(breakdown).to receive_messages(
        initially_planned: planned,
        changed_after_start: changed,
        completed:,
        unfinished:,
        reference_start: Timestamp.new(sprint.started_at),
        reference_finish: Timestamp.now,
        done_status_ids: [1, 2]
      )
    end

    context "when entitled to baseline comparison", with_ee: %i[baseline_comparison] do
      it "renders a heading, count and story points for each block" do
        expect(rendered_component).to have_css(".op-wp-overview--blocks")
        expect(rendered_component).to have_text("Initially planned")
        expect(rendered_component).to have_text("Scope change")
        expect(rendered_component).to have_text("Completed")
        expect(rendered_component).to have_text("Unfinished")
        expect(rendered_component).to have_text("5")
        expect(rendered_component).to have_text("13 story points")
        expect(rendered_component).to have_text("+4 / -1")
        expect(rendered_component).to have_text("+6 / -2 story points")
        expect(rendered_component).to have_text("View all", count: 4)

        expect(rendered_component).to have_no_css(".blankslate")
      end

      it "colors the completed count green and the unfinished count muted" do
        expect(rendered_component).to have_css(".color-fg-success", text: "3")
        expect(rendered_component).to have_css(".color-fg-muted", text: "2")
      end

      it "links each block's 'View all' to the work packages table filtered to the sprint" do
        links = rendered_component.css("a", text: "View all")
        expect(links).not_to be_empty

        query_props = links.map { |link| JSON.parse(CGI.parse(URI.parse(link["href"]).query)["query_props"].first) }

        expect(query_props).to all(include("f" => include(include("n" => "sprintId"))))
        expect(query_props).to all(include("ts"))
      end
    end

    context "when not entitled to baseline comparison" do
      it "still renders the heading, count and story points for each block" do
        expect(rendered_component).to have_css(".op-wp-overview--blocks")
        expect(rendered_component).to have_text("Initially planned")
        expect(rendered_component).to have_text("Scope change")
        expect(rendered_component).to have_text("+4 / -1")
      end

      it "hides every block's 'View all' link" do
        expect(rendered_component).to have_no_text("View all")
      end
    end

    it "bases the progress bar on the sums of story points" do
      expect(rendered_component.css(".Progress-item").first["style"]).to include("width: 62%")
    end

    it "summarizes the progress in story points next to the bar" do
      expect(rendered_component).to have_text("62% (8 of 13 story points)")
    end

    context "when the project's estimation unit is time", with_flag: { project_settings_estimation_unit: true } do
      before { project.estimation_unit = "time" }

      it "shows estimated time instead of story points for each block" do
        expect(rendered_component).to have_no_text("story points")
        expect(rendered_component).to have_text(DurationConverter.output(20))
        expect(rendered_component).to have_text(DurationConverter.output(12))
        expect(rendered_component).to have_text(DurationConverter.output(28))
        expect(rendered_component).to have_text(
          "+#{DurationConverter.output(10)} / -#{DurationConverter.output(4)}", normalize_ws: true
        )
      end

      it "bases the progress bar on the sums of estimated hours" do
        expect(rendered_component.css(".Progress-item").first["style"]).to include("width: 30%")
      end

      it "summarizes the progress using the formatted duration next to the bar" do
        expect(rendered_component).to have_text(
          "30% (#{DurationConverter.output(12)} of #{DurationConverter.output(40)})"
        )
      end

      context "when the duration format is set to days and hours", with_settings: { duration_format: "days_and_hours" } do
        it "summarizes the progress in days and hours rather than a plain hour count" do
          expect(rendered_component).to have_text("30% (1d 4h of 5d 0h)")
        end
      end
    end

    context "when the project's estimation unit is none", with_flag: { project_settings_estimation_unit: true } do
      before { project.estimation_unit = "none" }

      it "shows only the work package counts, without story points or estimated time" do
        expect(rendered_component).to have_no_text("story points")
        expect(rendered_component).to have_text("5")
        expect(rendered_component).to have_text("3")
        expect(rendered_component).to have_text("2")
      end

      it "bases the progress bar on the work package counts" do
        expect(rendered_component.css(".Progress-item").first["style"]).to include("width: 60%")
      end

      it "summarizes the progress in work packages next to the bar" do
        expect(rendered_component).to have_text("60% (3 of 5 work packages)")
      end
    end
  end

  describe "visibility" do
    let(:project) { create(:project) }
    let(:type_feature) { create(:type_feature) }
    let(:issue_open) { create(:status, name: "Open", is_default: true) }
    let(:sprint) do
      create(:sprint, project:,
                      start_date: Time.zone.today - 5.days,
                      finish_date: Time.zone.today + 5.days,
                      started_at: 5.days.ago)
    end

    let!(:work_package) do
      create(:work_package, project:, sprint:, type: type_feature, status: issue_open, story_points: 5,
                            created_at: sprint.start_date - 1.day, updated_at: sprint.start_date - 1.day)
    end

    before do
      work_package.last_journal.update_columns(
        created_at: work_package.created_at,
        updated_at: work_package.created_at,
        validity_period: work_package.created_at..Float::INFINITY
      )
    end

    def block_count(heading)
      block = rendered_component.css(".op-wp-overview--blocks > div").find { |node| node.text.include?(heading) }
      block.css("p.f1").text
    end

    def title_counter_text
      rendered_component.css(".Counter").text
    end

    context "when the current user can view the project's work packages" do
      let(:role) { create(:project_role, permissions: %i[view_sprints view_work_packages]) }

      current_user { create(:user, member_with_roles: { project => role }) }

      it "counts the work package's story points in the progress bar" do
        expect(rendered_component).to have_text("0 of 5 story points")
      end

      it "counts the work package in the initially planned and unfinished boxes" do
        expect(block_count("Initially planned")).to eq("1")
        expect(block_count("Unfinished")).to eq("1")
      end

      it "reports no scope change, since the work package never moved in or out of the sprint" do
        expect(block_count("Scope change")).to eq("+0 / -0")
      end

      it "shows a counter in the title for the total number of work packages" do
        expect(title_counter_text).to eq("1")
      end
    end

    context "when the current user has no permission to view the project's work packages" do
      let(:role) { create(:project_role, permissions: [:view_sprints]) }

      current_user { create(:user, member_with_roles: { project => role }) }

      it "excludes the work package from the progress bar" do
        expect(rendered_component).to have_text("0 of 0 story points")
      end

      it "excludes the work package from every breakdown box" do
        expect(block_count("Initially planned")).to eq("0")
        expect(block_count("Scope change")).to eq("+0 / -0")
        expect(block_count("Completed")).to eq("0")
        expect(block_count("Unfinished")).to eq("0")
      end

      it "excludes the work package from the title counter" do
        expect(title_counter_text).to eq("0")
      end
    end

    context "when the current user lacks permission to view sprints at all" do
      let(:role) { create(:project_role, permissions: [:view_work_packages]) }

      current_user { create(:user, member_with_roles: { project => role }) }

      it "does not render the widget" do
        expect(rendered_component.to_html).to be_blank
      end
    end
  end

  context "when the sprint has no date range set" do
    let(:sprint) { build_stubbed(:sprint, project:, start_date: nil, finish_date: nil) }

    current_user { build_stubbed(:user) }

    before do
      mock_permissions_for(current_user) { |mock| mock.allow_in_project(:view_sprints, project:) }
    end

    it "renders a blankslate" do
      expect(rendered_component).to have_css(".blankslate", text: "No sprint data available")
      expect(rendered_component).to have_no_css(".op-wp-overview--blocks")
    end
  end
end
