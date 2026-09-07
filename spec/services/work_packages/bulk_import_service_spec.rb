# frozen_string_literal: true

require "spec_helper"

RSpec.describe WorkPackages::BulkImportService, type: :service do
  let(:user) { instance_double(User) }
  let(:project) { instance_double(Project) }

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
      expect(result.errors.full_messages).to include("Could not read the uploaded file: Only CSV and XLSX files are supported.")
    end
  end

  describe "CSV files" do
    let(:file) do
      instance_double(
        ActionDispatch::Http::UploadedFile,
        original_filename: "work-packages.csv",
        read: "Subject,Description\nFirst package,First description\nSecond package,Second description\n"
      )
    end
    let(:create_service) { instance_double(WorkPackages::CreateService) }

    it "creates every row through the work package creation service" do
      first_work_package = instance_double(WorkPackage)
      second_work_package = instance_double(WorkPackage)
      allow(WorkPackages::CreateService).to receive(:new).with(user: user).and_return(create_service)
      allow(create_service).to receive(:call).with({
        subject: "First package",
        description: "First description",
        project: project
      }).and_return(ServiceResult.success(result: first_work_package))
      allow(create_service).to receive(:call).with({
        subject: "Second package",
        description: "Second description",
        project: project
      }).and_return(ServiceResult.success(result: second_work_package))

      result = described_class.new(user: user, project: project, file: file).call

      expect(result).to be_success
      expect(result.result).to contain_exactly(first_work_package, second_work_package)
    end

    it "reports row errors and does not return created work packages" do
      valid_work_package = instance_double(WorkPackage)
      invalid_work_package = WorkPackage.new
      invalid_work_package.errors.add(:subject, "is invalid")
      failure = ServiceResult.failure(result: invalid_work_package)
      allow(WorkPackages::CreateService).to receive(:new).with(user: user).and_return(create_service)
      allow(create_service).to receive(:call).with({
        subject: "First package",
        description: "First description",
        project: project
      }).and_return(ServiceResult.success(result: valid_work_package))
      allow(create_service).to receive(:call).with({
        subject: "Second package",
        description: "Second description",
        project: project
      }).and_return(failure)

      result = described_class.new(user: user, project: project, file: file).call

      expect(result).not_to be_success
      expect(result.result).to be_nil
      expect(result.errors.full_messages.join).to include("Row 3", "Subject is invalid")
    end
  end
end