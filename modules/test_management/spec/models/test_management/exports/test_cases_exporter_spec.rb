# frozen_string_literal: true

require "spec_helper"
require "spreadsheet"

RSpec.describe TestManagement::Exports::TestCasesExporter do
  shared_let(:project) { create(:project, name: "Shop", enabled_module_names: %i[test_management work_package_tracking]) }
  shared_let(:user) do
    create(:user, firstname: "Erin", lastname: "Export",
                  member_with_permissions: { project => %i[view_test_cases view_work_packages] })
  end
  shared_let(:hidden_project) { create(:project) }

  let(:root) { create(:tm_suite, project:, name: "Accounts") }
  let(:child) { create(:tm_suite, project:, parent: root, name: "Sign in") }
  let(:visible_wp) { create(:work_package, project:, subject: "Release 1") }
  let(:hidden_wp) { create(:work_package, project: hidden_project, subject: "Secret") }
  let!(:test_case) do
    create(:tm_test_case, project:, suite: child, title: "Valid sign in", priority: "high",
                          status: "ready", automated: true, preconditions: "Account exists", author: user).tap do |tc|
      tc.steps.create!(position: 0, action: "Open the page", expected_result: "Form shown")
      tc.steps.create!(position: 1, action: "Submit", data: "a@b.c", expected_result: "Signed in")
      tc.labels << create(:tm_label, project:, name: "smoke")
      tc.labels << create(:tm_label, project:, name: "API")
      TestManagement::TestCaseWorkPackage.create!(test_case: tc, work_package: visible_wp)
      TestManagement::TestCaseWorkPackage.create!(test_case: tc, work_package: hidden_wp)
    end
  end
  let!(:unfiled_case) { create(:tm_test_case, project:, title: "Loose") }
  let!(:other_case) { create(:tm_test_case, project:, suite: create(:tm_suite, project:, name: "Reports"), title: "Report") }

  def export(format, scope: "project", params: {})
    described_class.new(TestManagement::TestCasesQuery.new(project, params),
                        format:, scope:, project:, current_user: user).export!
  end

  def parsed_csv(params = {})
    content = export("csv", **params).content
    CSV.parse(content.delete_prefix("\xEF\xBB\xBF"), col_sep: I18n.t(:general_csv_separator))
  end

  describe "CSV" do
    it "returns a CSV result with a UTF-8 BOM and a sane file name" do
      result = export("csv")

      expect(result.mime_type).to eq("text/csv")
      expect(result.title).to match(/\ATest_cases_-_Shop_\d{4}-\d{2}-\d{2}\.csv\z/)
      expect(result.content).to start_with("\xEF\xBB\xBF")
    end

    it "writes scope, total, all columns and one row per case (unfiled last)" do
      rows = parsed_csv
      header_index = rows.index { |row| row.first == "id" }

      expect(rows[1]).to eq(["Scope", "Whole project"])
      expect(rows[header_index]).to eq(["id", "Title", "Folder", "Priority", "Status", "Automated", "Labels",
                                        "Linked work packages", "Preconditions", "Steps", "Created by",
                                        "Created at", "Last edited by", "Last edited at"])
      data = rows[(header_index + 1)..]
      expect(data.pluck(1)).to eq(["Valid sign in", "Report", "Loose"])
      expect(data.last[2]).to eq("Unfiled")
    end

    it "flattens labels, visible work packages and steps" do
      row = parsed_csv.find { |r| r[1] == "Valid sign in" }

      expect(row[2]).to eq("Accounts / Sign in")
      expect(row[5]).to eq("Yes")
      expect(row[6]).to eq("API; smoke")
      expect(row[7]).to eq("##{visible_wp.id} Release 1")
      expect(row[8]).to eq("Account exists")
      expect(row[9]).to eq("1. Open the page | Expected: Form shown\n2. Submit | Data: a@b.c | Expected: Signed in")
      expect(row[10]).to eq("Erin Export")
    end

    it "exports a folder with its subfolders" do
      rows = parsed_csv(scope: "folder", params: { suite_id: root.id.to_s })

      expect(rows[1]).to eq(["Scope", "Folder: Accounts (including subfolders)"])
      expect(rows.pluck(1)).to include("Valid sign in")
      expect(rows.pluck(1)).not_to include("Report", "Loose")
    end

    it "exports the current filter" do
      rows = parsed_csv(scope: "filter", params: { q: "loose" })

      expect(rows[1].last).to include('Title contains "loose"')
      expect(rows.pluck(1)).to include("Loose")
      expect(rows.pluck(1)).not_to include("Report")
    end

    it "escapes formula-like cells when the setting is on", with_settings: { csv_escape_formulas: true } do
      test_case.update_column(:title, "=1+1")
      expect(parsed_csv.pluck(1)).to include("'=1+1")
    end
  end

  it "renders an Excel workbook" do
    result = export("xls")
    expect(result.mime_type).to eq("application/vnd.ms-excel")
    expect(result.title).to end_with(".xls")

    sheet = Spreadsheet.open(StringIO.new(result.content)).worksheet(0)
    expect(sheet.rows.pluck(1)).to include("Valid sign in")
  end

  it "renders a PDF" do
    result = export("pdf")

    expect(result.mime_type).to eq("application/pdf")
    expect(result.content).to start_with("%PDF")
    text = PDF::Inspector::Text.analyze(result.content).strings.join(" ") if defined?(PDF::Inspector)
    expect(text).to include("Valid sign in") if text
  end

  it "renders a PDF for an empty project" do
    empty = create(:project)
    result = described_class.new(TestManagement::TestCasesQuery.new(empty), format: "pdf", project: empty,
                                                                            current_user: user).export!
    expect(result.content).to start_with("%PDF")
  end

  it "rejects unknown formats" do
    expect { export("docx") }.to raise_error(ArgumentError)
  end
end
