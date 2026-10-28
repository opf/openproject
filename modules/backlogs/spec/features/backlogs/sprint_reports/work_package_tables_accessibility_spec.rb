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

RSpec.describe "Sprint report work package table accessibility", :js, with_ee: %i[baseline_comparison sprint_report_pro_widgets],
                                                                      with_flag: :sprint_reports do
  include Rails.application.routes.url_helpers

  shared_let(:project) { create(:project) }
  shared_let(:closed_status) { create(:closed_status) }
  shared_let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_sprints view_work_packages show_board_views edit_work_packages]
           })
  end

  let(:completed_at) { nil }
  let(:sprint) do
    create(:sprint, project:, name: "Accessible sprint", start_date: 7.days.ago,
                    finish_date: Date.tomorrow, started_at: 5.days.ago,
                    completed_at:, status: completed_at ? :completed : :active)
  end
  let!(:added_and_completed) do
    create(:work_package, project:, sprint:, subject: "Completed current subject", status: closed_status,
                          journals: {
                            6.days.ago => { sprint_id: nil, subject: "Completed previous subject" },
                            4.days.ago => { subject: "Completed previous subject" },
                            2.days.ago => {}
                          })
  end
  let!(:kept) do
    create(:work_package, project:, sprint:, subject: "Unfinished current subject",
                          journals: {
                            6.days.ago => { subject: "Unfinished previous subject" },
                            2.days.ago => {}
                          })
  end
  let!(:removed) do
    create(:work_package, project:, subject: "Removed current subject",
                          journals: {
                            6.days.ago => { sprint_id: sprint.id, subject: "Removed previous subject" },
                            4.days.ago => { subject: "Removed previous subject" },
                            2.days.ago => {}
                          })
  end

  current_user { user }

  def report_table(title)
    Pages::EmbeddedWorkPackagesTable.new(find(".op-sprint-report-wp-table", text: title), table_name: title)
  end

  def report_row(table, work_package)
    table.treegrid.find("tr[data-work-package-id='#{work_package.id}']")
  end

  def focus_report_row(table, work_package)
    report_row(table, work_package).execute_script("this.focus()")
    table.expect_focus_on_row(work_package)
  end

  shared_examples "accessible read-only sprint tables" do
    before do
      visit project_backlogs_sprint_report_path(project, sprint)
    end

    let(:tables) do
      {
        "Completed work" => added_and_completed,
        "Unfinished work" => kept,
        "Scope increase after sprint start" => added_and_completed,
        "Scope decrease after sprint start" => removed
      }
    end

    it "names all four tables and keeps their row headers clean while editing stays disabled" do
      tables.each do |title, work_package|
        table = report_table(title)
        row = report_row(table, work_package)
        expect(row).to have_selector(:role, "rowheader", accessible_name: work_package.subject, exact: true)
        header = row.find(:role, "rowheader", accessible_name: work_package.subject, exact: true)
        expect(header["data-row-header-name"]).to eq(work_package.subject)
        expect(row).to have_no_css(".inline-edit--display-field.-editable")
        expect(row).to have_selector(:link, accessible_name: work_package.id.to_s,
                                            accessible_description: "", exact: true)
        table.expect_row_positions(rowcount: 2, rows: [1, 2])
        label_id = table.treegrid["aria-labelledby"]
        expect(page).to have_css("##{label_id}", count: 1)
        expect(find("##{label_id}")).to have_heading(title, level: 3, exact: true)

        header.click
        expect(row).to have_no_selector(:role, "textbox")
        focus_report_row(table, work_package)
        table.press_keys(:right, :right)
        table.expect_focus_on_cell(work_package, :subject)
        table.press_keys(:enter, :f2)
        table.expect_focus_on_cell(work_package, :subject)
        expect(row).to have_no_selector(:role, "textbox")

        id = row.find(:link, accessible_name: work_package.id.to_s, exact: true)
        id.hover
        expect(row).to have_no_css("tool-tip", visible: :visible)
      end
      expect(page).to have_selector(:table, role: "treegrid", count: 4)
    end

    it "keeps selection and native Tab walks local when two widgets share a record" do
      completed = report_table("Completed work")
      unfinished = report_table("Unfinished work")
      increased = report_table("Scope increase after sprint start")
      report_row(increased, added_and_completed)
      focus_report_row(completed, added_and_completed)
      completed.press_keys(%i[shift space])
      expect(report_row(completed, added_and_completed)).to match_selector(:row, aria: { selected: true })
      expect(report_row(increased, added_and_completed)).to match_selector(:row, aria: { selected: false })
      completed.press_keys(:tab)
      expect(report_row(completed, added_and_completed))
        .to have_selector(:link, accessible_name: added_and_completed.id.to_s, focused: true, exact: true)
      completed.press_keys(:tab)
      unfinished.expect_focus_on_row(kept)
      completed.expect_focus_outside_table

      focus_report_row(increased, added_and_completed)
      increased.press_keys(%i[shift space])
      expect(report_row(increased, added_and_completed)).to match_selector(:row, aria: { selected: true })
      increased.press_keys(%i[shift space])
      expect(report_row(increased, added_and_completed)).to match_selector(:row, aria: { selected: false })
      expect(report_row(completed, added_and_completed)).to match_selector(:row, aria: { selected: true })
      focus_report_row(completed, added_and_completed)
      completed.press_keys(:right)
      completed.expect_focus_on_cell(added_and_completed, :id)
      completed.press_keys(:left)
      completed.expect_focus_on_row(added_and_completed)
    end

    it "opens the work package from its ID link without activating an editor" do
      table = report_table("Completed work")
      row = report_row(table, added_and_completed)
      expect(row).to have_no_selector(:role, "textbox")
      row.find(:link, accessible_name: added_and_completed.id.to_s, exact: true).click

      Pages::FullWorkPackage.new(added_and_completed, project).ensure_loaded
      expect(page).to have_current_path(/\/work_packages\/#{added_and_completed.id}(?:\/|$)/, ignore_query: true)
    end
  end

  context "with current results for an active sprint" do
    include_examples "accessible read-only sprint tables"
  end

  context "with historical results for a completed sprint" do
    let(:completed_at) { 1.day.ago }

    include_examples "accessible read-only sprint tables"
  end
end
