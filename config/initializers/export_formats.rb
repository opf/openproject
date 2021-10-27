OpenProject::Application.configure do |application|
  application.config.to_prepare do
    ::Exports::Register.register do
      list WorkPackage, WorkPackage::Exports::CSV
      list WorkPackage, ::WorkPackage::PDFExport::WorkPackageListToPdf

      single WorkPackage, ::WorkPackage::PDFExport::WorkPackageToPdf

      formatter WorkPackage, WorkPackage::Exports::Formatters::Costs
      formatter WorkPackage, WorkPackage::Exports::Formatters::EstimatedHours

      list Project, Projects::Exports::CSV
    end
  end
end
