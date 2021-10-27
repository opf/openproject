OpenProject::Application.configure do |application|
  application.config.to_prepare do
    ::Exports::Register.register do
      list WorkPackage, WorkPackage::Exports::CSV
      list WorkPackage, ::WorkPackage::PDFExport::WorkPackageListToPdf

      single WorkPackage, ::WorkPackage::PDFExport::WorkPackageToPdf

      formatter WorkPackage, WorkPackage::Exports::Formatters::Costs
      formatter WorkPackage, WorkPackage::Exports::Formatters::EstimatedHours
      formatter WorkPackage, Exports::Formatters::CustomField

      list Project, Projects::Exports::CSV
      formatter Project, Exports::Formatters::CustomField
      formatter Project, Projects::Exports::Formatters::Status
    end
  end
end
