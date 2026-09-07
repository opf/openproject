# frozen_string_literal: true

require "spec_helper"

RSpec.describe WorkPackages::BulkImportService, type: :service do
  describe ".sample_csv" do
    it "contains the supported import columns" do
      headers = CSV.parse(described_class.sample_csv, headers: true).headers

      expect(headers).to include("Subject", "Type", "Description", "% Complete")
    end
  end

  describe "unsupported files" do
    it "returns an error" do
      file = instance_double(ActionDispatch::Http::UploadedFile, original_filename: "work-packages.txt")

      result = described_class.new(user: nil, project: nil, file: file).call

      expect(result).not_to be_success
      expect(result.errors.full_messages).to include("Only CSV and XLSX files are supported.")
    end
  end
end