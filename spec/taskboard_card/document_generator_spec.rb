require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe OpenProject::PdfExport::TaskboardCard::DocumentGenerator do
  # let(:pdf) { Prawn::Document.new(:margin => 0) }
  let(:config) { TaskboardCardConfiguration.new({
    name: "Default",
    identifier: "default",
    per_page: 1,
    page_size: "A4",
    orientation: "landscape",
    rows: "rows:\n    row1:\n      has_border: false\n      columns:\n        id:\n          has_label: false\n          font_size: 15\n    row1:\n      has_border: false\n      columns:\n        subject:\n          has_label: false\n          font_size: 15"
  })}
  let(:work_package) { WorkPackage.new({
    id: 1234,
    subject: "Test work package",
    description: "This is a test work package"
  })}

  it 'shows work package subject' do
    work_packages = [work_package]
    generator = OpenProject::PdfExport::TaskboardCard::DocumentGenerator.new(config, work_packages)

    text = PDF::Inspector::Text.analyze(generator.render)
    text.strings.join.should == 'Test work package'
  end

end