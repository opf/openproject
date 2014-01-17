require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe OpenProject::PdfExport::TaskboardCard::DocumentGenerator do
  let(:config) { TaskboardCardConfiguration.new({
    name: "Default",
    identifier: "default",
    per_page: 1,
    page_size: "A4",
    orientation: "landscape",
    rows: "rows:\n    row1:\n      has_border: false\n      columns:\n        subject:\n          has_label: false\n          font_size: 15\n    row2:\n      has_border: false\n      columns:\n        non_existent:\n          has_label: false\n          font_size: 15\n          has_label: true\n          render_if_empty: true"
  })}

  let(:work_package1) { WorkPackage.new({
    subject: "Work package 1",
    description: "This is work package 1"
  })}

  let(:work_package2) { WorkPackage.new({
    subject: "Work package 2",
    description: "This is work package 2"
  })}

  describe "Single work package rendering" do
    before(:each) do
      work_packages = [work_package1]
      @generator = OpenProject::PdfExport::TaskboardCard::DocumentGenerator.new(config, work_packages)
    end

    it 'shows work package subject' do
      text_analysis = PDF::Inspector::Text.analyze(@generator.render)
      text_analysis.strings.include?('Work package 1').should be_true
    end

    it 'shows empty field label' do
      text_analysis = PDF::Inspector::Text.analyze(@generator.render)
      text_analysis.strings.include?('Non existent:-').should be_true
    end

    it 'should be 1 page' do
      page_analysis = PDF::Inspector::Page.analyze(@generator.render)
      page_analysis.pages.size.should == 1
    end
  end

  describe "Multiple work package rendering" do
    before(:each) do
      work_packages = [work_package1, work_package2]
      @generator = OpenProject::PdfExport::TaskboardCard::DocumentGenerator.new(config, work_packages)
    end

    it 'shows work package subject' do
      text = PDF::Inspector::Text.analyze(@generator.render)
      text.strings.include?('Work package 1').should be_true
      text.strings.include?('Work package 2').should be_true
    end

    it 'should be 2 pages' do
      page_analysis = PDF::Inspector::Page.analyze(@generator.render)
      page_analysis.pages.size.should == 2
    end
  end

end