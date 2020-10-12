require 'spec_helper'
require 'spreadsheet'

describe "WorkPackageXlsExport Custom Fields" do
  let(:type) { FactoryBot.create :type }
  let(:project) { FactoryBot.create :project, types: [type] }

  let!(:custom_field) do
    FactoryBot.create(
        :list_wp_custom_field,
        name: "Ingredients",
        multi_value: true,
        types: [type],
        projects: [project],
        possible_values: ["ham", "onions", "pineapple", "mushrooms"]
    )
  end

  def custom_values_for(*values)
    values.map do |str|
      custom_field.custom_options.find { |co| co.value == str }.try(:id)
    end
  end

  let(:work_package1) do
    wp = FactoryBot.create :work_package, project: project, type: type
    wp.custom_field_values = {
      custom_field.id => custom_values_for('ham', 'onions')
    }
    wp.save
    wp
  end

  let(:work_package2) do
    wp = FactoryBot.create :work_package, project: project, type: type
    wp.custom_field_values = {
      custom_field.id => custom_values_for('pineapple')
    }
    wp.save
    wp
  end

  let(:work_package3) { FactoryBot.create :work_package, project: project, type: type }
  let(:work_packages) { [work_package1, work_package2, work_package3] }
  let(:current_user) { FactoryBot.create :admin }

  let!(:query) do
    query              = FactoryBot.build(:query, user: current_user, project: project)
    query.column_names = ['subject', "cf_#{custom_field.id}"]
    query.sort_criteria = [%w[id asc]]

    query.save!
    query
  end

  let(:sheet) do
    login_as(current_user)
    work_packages
    query

    load_sheet export
  end

  let(:export) do
    XlsExport::WorkPackage::Exporter::XLS.new query
  end

  def load_sheet(export)
    f = Tempfile.new 'result.xls'
    begin
      f.binmode
      f.write export.list(&:content)
    ensure
      f.close
    end

    sheet = Spreadsheet.open(f.path).worksheets.first
    f.unlink

    sheet
  end

  it 'produces the valid XLS result' do
    expect(query.columns.map(&:name)).to eq [:subject, :"cf_#{custom_field.id}"]
    expect(sheet.rows.first.take(2)).to eq ['Subject', 'Ingredients']

    # Subjects
    expect(sheet.row(1)[0]).to eq(work_package1.subject)
    expect(sheet.row(2)[0]).to eq(work_package2.subject)
    expect(sheet.row(3)[0]).to eq(work_package3.subject)

    # CF values
    expect(sheet.row(1)[1]).to eq('ham, onions')
    expect(sheet.row(2)[1]).to eq('pineapple')
    expect(sheet.row(3)[1]).to eq(nil)
  end
end
