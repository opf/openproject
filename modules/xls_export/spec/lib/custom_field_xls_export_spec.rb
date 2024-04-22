require "spec_helper"
require "spreadsheet"

RSpec.describe "WorkPackageXlsExport Custom Fields" do
  let(:type) { create(:type) }
  let(:project) { create(:project, types: [type]) }

  let!(:custom_field) do
    create(
      :list_wp_custom_field,
      name: "Ingredients",
      multi_value: true,
      types: [type],
      projects: [project],
      possible_values: ["ham", "onions", "pineapple", "mushrooms"]
    )
  end

  let(:work_package1) do
    wp = create(:work_package, project:, type:)
    wp.custom_field_values = {
      custom_field.id => custom_values_for("ham", "onions")
    }
    wp.save
    wp
  end

  let(:work_package2) do
    wp = create(:work_package, project:, type:)
    wp.custom_field_values = {
      custom_field.id => custom_values_for("pineapple")
    }
    wp.save
    wp
  end

  let(:work_package3) { create(:work_package, project:, type:) }
  let(:work_packages) { [work_package1, work_package2, work_package3] }
  let(:current_user) { create(:admin) }

  let!(:query) do
    query              = build(:query, user: current_user, project:)
    query.column_names = ["subject", custom_field.column_name]
    query.sort_criteria = [%w[id asc]]

    query.save!
    query
  end

  let(:export) do
    XlsExport::WorkPackage::Exporter::XLS.new query
  end

  let(:sheet) do
    login_as(current_user)
    work_packages
    query

    io = StringIO.new(export.export!.content)
    Spreadsheet.open(io).worksheets.first
  end

  def custom_values_for(*values)
    values.map do |str|
      custom_field.custom_options.find { |co| co.value == str }.try(:id)
    end
  end

  it "produces the valid XLS result" do
    expect(query.columns.map(&:name)).to eq [:subject, custom_field.column_name.to_sym]
    expect(sheet.rows.first.take(2)).to eq ["Subject", "Ingredients"]

    # Subjects
    expect(sheet.row(1)[0]).to eq(work_package1.subject)
    expect(sheet.row(2)[0]).to eq(work_package2.subject)
    expect(sheet.row(3)[0]).to eq(work_package3.subject)

    # CF values
    expect(sheet.row(1)[1]).to eq("ham, onions")
    expect(sheet.row(2)[1]).to eq("pineapple")
    expect(sheet.row(3)[1]).to be_nil
  end
end
