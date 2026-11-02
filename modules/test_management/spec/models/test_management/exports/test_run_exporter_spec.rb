# frozen_string_literal: true

require "spec_helper"
require "spreadsheet"

RSpec.describe TestManagement::Exports::TestRunExporter do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) { create(:user, firstname: "Rita", lastname: "Runner") }

  let(:folder) { create(:tm_suite, project:, name: "Checkout") }
  let(:run) do
    create(:tm_test_run, :in_progress, project:, name: "Sprint 9", assigned_to: user, author: user,
                                       start_date: Date.new(2026, 11, 2), end_date: Date.new(2026, 11, 6))
  end
  let!(:passed) do
    create(:tm_test_run_case, test_run: run, status: "passed", assigned_to: user,
                              test_case: create(:tm_test_case, project:, suite: folder, title: "Pay by card"))
  end
  let!(:failed) do
    create(:tm_test_run_case, test_run: run, status: "failed",
                              test_case: create(:tm_test_case, project:, title: "Loose case"))
  end
  let!(:untested) do
    create(:tm_test_run_case, test_run: run,
                              test_case: create(:tm_test_case, project:, suite: folder, title: "Pay by voucher"))
  end

  before do
    create(:tm_test_result, run_case: passed, user:, status: "in_progress", comment: "Started")
    create(:tm_test_result, run_case: passed, user:, status: "passed", comment: "All good")
  end

  def export(format)
    described_class.new(run, format:, current_user: user).export!
  end

  def csv_rows
    CSV.parse(export("csv").content.delete_prefix("\xEF\xBB\xBF"), col_sep: I18n.t(:general_csv_separator))
  end

  it "starts with run info, state, statistics and pass rate" do
    rows = csv_rows.to_h { |r| [r[0], r[1]] }

    expect(rows["Run"]).to eq("#{run.formatted_id} Sprint 9")
    expect(rows["State"]).to eq("In progress")
    expect(rows["Assigned to"]).to eq("Rita Runner")
    expect(rows["Test cases"]).to eq("3")
    expect(rows["Passed"]).to eq("1 (33%)")
    expect(rows["Failed"]).to eq("1 (33%)")
    expect(rows["Pass rate"]).to eq("33%")
  end

  it "lists cases grouped by folder with assignee, status and the last result" do
    rows = csv_rows
    header = rows.index { |r| r.first == "id" }

    expect(rows[header]).to eq(["id", "Title", "Folder", "Labels", "Assigned to", "Status",
                                "Last result comment", "Result by", "Result at", "Failed step", "Error"])
    data = rows[(header + 1)..]
    expect(data.map { |r| [r[1], r[2]] })
      .to eq([["Pay by card", "Checkout"], ["Pay by voucher", "Checkout"], ["Loose case", "Unfiled"]])
    expect(data.first.values_at(4, 5, 6, 7)).to eq(["Rita Runner", "Passed", "All good", "Rita Runner"])
    expect(data.second[5]).to eq("Untested")
  end

  it "uses the frozen final status of a finished run" do
    run.update_columns(state: "completed")
    failed.update_columns(status: "passed", final_status: "failed")

    expect(csv_rows.find { |r| r[1] == "Loose case" }[5]).to eq("Failed")
  end

  it "leaves out soft-deleted cases" do
    untested.test_case.soft_delete!
    expect(csv_rows.pluck(1)).not_to include("Pay by voucher")
  end

  it "renders Excel and PDF" do
    xls = export("xls")
    sheet = Spreadsheet.open(StringIO.new(xls.content)).worksheet(0)
    expect(sheet.rows.pluck(0)).to include("Pass rate")

    pdf = export("pdf")
    expect(pdf.content).to start_with("%PDF")
    expect(pdf.title).to match(/\ATest_run_R\d+_Sprint_9_\d{4}-\d{2}-\d{2}\.pdf\z/)
  end
end
