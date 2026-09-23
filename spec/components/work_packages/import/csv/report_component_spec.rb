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

RSpec.describe WorkPackages::Import::CSV::ReportComponent, type: :component do
  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:user) }

  let(:base) do
    {
      "project_id" => project.id,
      "filename" => "sprint-43-scope.csv",
      "attachment_id" => 918,
      "dry_run" => true,
      "row_count" => 142,
      "created_count" => 142,
      "back_dated" => 0,
      "created_ids" => [],
      "assignee_count" => 11,
      "dated_count" => 118,
      "started_at" => "2026-09-21T09:00:00Z",
      "finished_at" => "2026-09-21T09:01:30Z",
      "counts" => { "type" => { "Task" => 96, "Bug" => 46 }, "status" => { "New" => 142 } },
      "problems" => [],
      "column_problems" => []
    }
  end

  def render_outcome(outcome, **overrides)
    status = build_stubbed(:delayed_job_status,
                           user:,
                           payload: base.merge("outcome" => outcome).merge(overrides))

    render_inline(described_class.new(status:, project:))
  end

  it "names the file it came from, so two open tabs are distinguishable" do
    render_outcome("checked")

    expect(page).to have_text("sprint-43-scope.csv")
  end

  describe "checked" do
    before { render_outcome("checked") }

    it "leads with what was checked" do
      expect(page).to have_text(I18n.t("work_packages.import.report.checked.title", count: 142))
    end

    it "gives four headline counts, each under its own subject" do
      expect(page).to have_text("Work packages 142", normalize_ws: true)
      expect(page).to have_text("Types 2", normalize_ws: true)
      expect(page).to have_text("Assignees 11", normalize_ws: true)
      expect(page).to have_text("#{I18n.t('work_packages.import.report.headline.dated.label')} 118", normalize_ws: true)
    end

    it "breaks the rows down per value, which a bare total does not" do
      expect(page).to have_text("Task 96", normalize_ws: true)
      expect(page).to have_text("Bug 46", normalize_ws: true)
      expect(page).to have_text("New 142", normalize_ws: true)
    end

    it "offers the import as a form carrying the attachment, not the file again" do
      expect(page).to have_button("Import 142 work packages")
      expect(page).to have_css("input[name='attachment_id'][value='918']", visible: :all)
      expect(page).to have_css("input[name='dry_run'][value='0']", visible: :all)
    end

    it "leads with a success banner carrying a title and a line beneath it" do
      expect(page).to have_css(".Banner--success")
      expect(page).to have_css(".Banner-title", text: I18n.t("work_packages.import.report.checked.title", count: 142))
      expect(page).to have_text("Nothing has been created yet. Review the summary below, then import.")
    end

    it "offers Clear beside the import button" do
      expect(page).to have_link("Clear", href: /work_packages\/import\z/)
    end

    # A page visit would re-bootstrap everything around the two regions it actually resets.
    it "resets Clear in place rather than navigating" do
      expect(page).to have_css("a[data-action='work-packages--csv-import#clear']", text: "Clear")
    end

    it "says the checked file is kept" do
      expect(page).to have_text("kept for a few hours")
    end
  end

  describe "imported" do
    it "leads with the count" do
      render_outcome("imported", "dry_run" => false)

      expect(page).to have_text("142 work packages created")
    end

    it "links to the work packages it created, filtered by author and creation window" do
      render_outcome("imported", "dry_run" => false)

      href = page.find_link("View the 142 imported work packages")[:href]
      props = JSON.parse(CGI.unescape(href.split("query_props=").last))

      expect(props["f"]).to include("n" => "createdAt", "o" => "<>d",
                                    "v" => ["2026-09-21T09:00:00Z", "2026-09-21T09:01:30Z"])
      expect(props["f"]).to include("n" => "author", "o" => "=", "v" => [user.id.to_s])
    end

    it "lists by id where the run was small enough to carry them, which back-dating cannot spoil" do
      render_outcome("imported", "dry_run" => false, "created_ids" => [11, 22, 33], "back_dated" => 2)

      href = page.find_link("View the 142 imported work packages")[:href]
      props = JSON.parse(CGI.unescape(href.split("query_props=").last))

      expect(props["f"]).to eq([{ "n" => "id", "o" => "=", "v" => %w[11 22 33] }])
      expect(page).to have_no_text("not in that list")
    end

    it "falls back to the creation window when no ids arrived and nothing was back-dated" do
      render_outcome("imported", "dry_run" => false)

      href = page.find_link("View the 142 imported work packages")[:href]
      props = JSON.parse(CGI.unescape(href.split("query_props=").last))

      expect(props["f"].pluck("n")).to eq(%w[createdAt author])
      expect(props["t"]).to eq("id:asc")
      expect(page).to have_no_text("newest first")
    end

    it "opens the project newest first when the ids do not fit and rows were back-dated" do
      stub_const("#{described_class}::LISTABLE_IDS", 2)

      render_outcome("imported", "dry_run" => false, "created_ids" => [11, 22, 33], "back_dated" => 2)

      href = page.find_link("View the 142 imported work packages")[:href]
      props = JSON.parse(CGI.unescape(href.split("query_props=").last))

      expect(props["f"]).to eq([{ "n" => "author", "o" => "=", "v" => [user.id.to_s] }])
      expect(props["t"]).to eq("id:desc")
      expect(page).to have_text("opens the project with the newest first")
    end

    it "offers a fresh start beside the link to what it created" do
      render_outcome("imported", "dry_run" => false)

      expect(page).to have_link("Import another file", href: /work_packages\/import\z/)
    end

    it "names the file and when the run finished, so the banner stands on its own" do
      render_outcome("imported", "dry_run" => false)

      expect(page).to have_css("code", text: "sprint-43-scope.csv")
      expect(page).to have_text("Imported from sprint-43-scope.csv on 09/21/2026 at", normalize_ws: true)
    end

    it "counts what was created per type, not just in total" do
      render_outcome("imported", "dry_run" => false)

      expect(page).to have_text("142 work packages", normalize_ws: true)
      expect(page).to have_text("96 Task", normalize_ws: true)
      expect(page).to have_text("46 Bug", normalize_ws: true)
    end

    it "says notifications were suppressed" do
      render_outcome("imported", "dry_run" => false)

      expect(page).to have_text("Notifications were not sent")
    end
  end

  describe "rows_rejected" do
    let(:problems) do
      [{ "row" => 7, "attribute" => "type", "value" => "Taks",
         "message" => "does not exist in this project." },
       { "row" => 9, "attribute" => "subject", "value" => "", "message" => "can't be blank." }]
    end

    before do
      render_outcome("rows_rejected",
                     "problems" => problems,
                     "created_count" => 0,
                     "available" => { "type" => %w[Task Bug Milestone] })
    end

    it "says nothing was imported and how much is wrong" do
      expect(page).to have_text("Nothing was imported: 2 problems in 2 lines")
    end

    it "gives the row, the column, the value and the problem" do
      expect(page).to have_text("Taks")
      expect(page).to have_text("does not exist in this project")
      expect(page).to have_text("7")
    end

    # An instance can have dozens of statuses, so the list stays folded away rather than
    # pushing every other problem off the screen.
    it "folds the available values behind a disclosure rather than into the message" do
      expect(page).to have_css("details summary", text: "3 available values")
      expect(page).to have_css("details", text: "Task, Bug, Milestone")
    end

    it "leaves the message alone for a problem that has no alternatives" do
      expect(page).to have_css("td", text: "can't be blank.")
      expect(page).to have_css("details", count: 1)
    end

    it "offers the same list as a CSV" do
      expect(page).to have_link("Download as CSV")
    end

    # A bare link is inline, so margin on it does nothing and the form below sits flush
    # against it.
    it "keeps the download in the footer, clear of whatever follows it" do
      expect(page).to have_css(".Box-footer a", text: "Download as CSV")
    end
  end

  describe "rows_rejected with more problems than the table shows" do
    let(:problems) do
      Array.new(described_class::SHOWN_PROBLEMS + 40) do |index|
        { "row" => index + 2, "attribute" => "subject", "value" => "", "message" => "can't be blank." }
      end
    end

    before { render_outcome("rows_rejected", "problems" => problems) }

    it "counts every problem and every line it rejected" do
      expect(page).to have_text("Nothing was imported: #{problems.size} problems in #{problems.size} lines")
    end

    it "shows the first of them and points at the download for the rest" do
      expect(page).to have_css("tbody tr", count: described_class::SHOWN_PROBLEMS)
      expect(page).to have_text("#{problems.size} problems, the first #{described_class::SHOWN_PROBLEMS} shown.")
    end
  end

  describe "file_rejected" do
    before do
      render_outcome("file_rejected",
                     "row_count" => 0,
                     "created_count" => 0,
                     "counts" => {},
                     "column_problems" => [{ "column" => "D", "header" => "Zustaendig",
                                             "message" => "cannot be imported." }])
    end

    it "leads with the headers, since there are no line numbers to give" do
      expect(page).to have_text("The column headers could not be read")
    end

    it "keys the table on the spreadsheet column letter" do
      expect(page).to have_text("D")
      expect(page).to have_text("Zustaendig")
      expect(page).to have_text("cannot be imported")
    end

    it "does not offer an import button" do
      expect(page).to have_no_button(/Import/)
    end
  end

  # A problem about the file as a whole names neither a column nor a header, so a table of it
  # would be one row of two empty cells.
  describe "file_rejected over the row limit" do
    before do
      render_outcome("file_rejected",
                     "row_count" => 0,
                     "created_count" => 0,
                     "counts" => {},
                     "column_problems" => [{ "column" => nil, "header" => nil,
                                             "message" => "This file has more rows than can be " \
                                                          "imported at once. The most is 5000." }])
    end

    it "puts the message in the banner" do
      expect(page).to have_css(".Banner-title", text: "This file has more rows than can be imported at once.")
      expect(page).to have_text("Nothing was imported.")
    end

    it "shows no table, since there is nothing to key it on" do
      expect(page).to have_no_table
      expect(page).to have_no_text("The column headers could not be read")
    end

    it "does not offer a download of the one message it already shows" do
      expect(page).to have_no_link("Download as CSV")
    end
  end
end
