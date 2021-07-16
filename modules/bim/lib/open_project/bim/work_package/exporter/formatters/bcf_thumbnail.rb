module OpenProject::Bim::WorkPackage::Exporter::Formatters
  class BcfThumbnail < WorkPackage::Exporter::Formatters::Default
    def self.apply?(column)
      column.is_a? ::Bim::Queries::WorkPackages::Columns::BcfThumbnailColumn
    end

    def format(work_package, column, **options)
      work_package&.bcf_issue&.viewpoints&.any? ? "x" : ''
    end
  end
end
