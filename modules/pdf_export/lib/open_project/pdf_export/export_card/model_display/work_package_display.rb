module OpenProject::PDFExport::ExportCard::ModelDisplay
  module WorkPackageDisplay
    def display_id
      "#{kind.is_standard ? '' : kind.name.to_s} ##{id}"
    end
  end
end
