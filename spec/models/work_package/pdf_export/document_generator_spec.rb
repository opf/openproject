# frozen_string_literal: true

require "spec_helper"
require "text/hyphen"

RSpec.describe WorkPackage::PDFExport::DocumentGenerator do
  include Redmine::I18n
  include PDFExportSpecUtils

  let(:project) { create(:project, name: "PDF Project") }
  let(:user) { create(:admin) }
  let(:description) do
    "This is a test description with an macro: workPackageValue:assignee"
  end
  let(:work_package) do
    create(:work_package,
           project:,
           description:,
           assigned_to: user,
           subject: "Document Generator Specs",
           type:)
  end
  let(:type) { create(:type, name: "Feature") }
  let(:options) do
    {}
  end
  let(:shared_options) do
    {
      footer_text_center: "A text in the center of the footer"
    }
  end
  let(:exporter) do
    described_class.new(work_package, shared_options.merge(options))
  end
  let(:export) do
    login_as(user)
    exporter
  end
  let(:export_time) { DateTime.new(2023, 6, 30, 23, 59) }
  let(:export_time_formatted) { format_time(export_time, include_date: true) }
  let(:export_date_formatted) { format_date(export_time) }
  let(:export_pdf) do
    Timecop.freeze(export_time) do
      export.export!
    end
  end

  subject(:pdf) do
    content = export_pdf.content
    # If you want to actually see the PDF for debugging, uncomment the following line
    # File.binwrite("WorkPackageDocumentGenerator-test-preview.pdf", content)
    PDF::Inspector::Text.analyze(content).strings
  end

  describe "#title" do
    context "in classic mode",
            with_settings: { work_packages_identifier: "classic" } do
      it "uses the numeric id in the filename" do
        expected_title = "PDF_Project_Feature_#{work_package.id}_Document_Generator_Specs_2023-06-30_23-59.pdf"
        expect(export_pdf.title).to eql(expected_title)
      end
    end

    context "in semantic mode",
            with_settings: { work_packages_identifier: "semantic" } do
      it "uses the semantic identifier in the filename" do
        expected_title = "PDF_Project_Feature_#{work_package.identifier}_Document_Generator_Specs_2023-06-30_23-59.pdf"
        expect(export_pdf.title).to eql(expected_title)
      end
    end
  end

  describe "with a request for a PDF" do
    it "contains correct data" do
      expected_result = [
        "This is a test description with an macro:",
        user.name,
        export_date_formatted,
        "A text in the center of the footer",
        "Page 1 of 1"
      ]
      result = pdf
      expect(result.join(" ")).to eq(expected_result.join(" "))
    end

    describe "with a work package mention in the description" do
      let(:other_work_package) { create(:work_package, project:, type:) }
      let(:description) { "##{other_work_package.id}" }

      it "renders the mention using formatted_id" do
        expect(pdf).to include(other_work_package.formatted_id)
      end
    end

    describe "with a request for a PDF with hyphenation and no header/footer text" do
      let(:options) do
        {
          hyphenation: "1",
          hyphenation_language: "en_us",
          footer_text_center: ""
        }
      end
      let(:description) do
        "honorificabilitudinitatibus " * 6
      end

      it "contains correct data" do
        expected_result = [
          "honorificabilitudinitatibus honorificabilitudinitatibus honorificabilitudinitatibus " \
          "honorificabili ­ tudinitatibus honorificabilitudinitatibus honorificabilitudinitatibus",
          export_date_formatted,
          "Page 1 of 1"
        ]
        result = pdf
        expect(result.join(" ")).to eq(expected_result.join(" "))
      end
    end
  end
end
