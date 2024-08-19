Rails.application.configure do |application|
  application.config.to_prepare do
    Exports::Register.register do
      list WorkPackage, WorkPackage::Exports::CSV
      list WorkPackage, WorkPackage::PDFExport::WorkPackageListToPdf

      single WorkPackage, WorkPackage::PDFExport::WorkPackageToPdf

      formatter WorkPackage, WorkPackage::Exports::Formatters::EstimatedHours
      formatter WorkPackage, WorkPackage::Exports::Formatters::RemainingHours
      formatter WorkPackage, WorkPackage::Exports::Formatters::SpentUnits
      formatter WorkPackage, WorkPackage::Exports::Formatters::Hours
      formatter WorkPackage, WorkPackage::Exports::Formatters::Days
      formatter WorkPackage, WorkPackage::Exports::Formatters::Currency
      formatter WorkPackage, WorkPackage::Exports::Formatters::Costs
      formatter WorkPackage, WorkPackage::Exports::Formatters::DoneRatio
      formatter WorkPackage, Exports::Formatters::CustomField
      formatter WorkPackage, Exports::Formatters::CustomFieldPdf

      list Project, Projects::Exports::CSV
      formatter Project, Exports::Formatters::CustomField
      formatter Project, Exports::Formatters::CustomFieldPdf
      formatter Project, Projects::Exports::Formatters::Status
      formatter Project, Projects::Exports::Formatters::Description
      formatter Project, Projects::Exports::Formatters::Public
      formatter Project, Projects::Exports::Formatters::Active
    end
  end
end
