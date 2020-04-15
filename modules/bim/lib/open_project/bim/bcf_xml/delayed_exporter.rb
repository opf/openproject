module OpenProject::Bim::BcfXml
  class DelayedExporter < ::WorkPackage::Exporter::Base
    def list
      export = create_export

      schedule_export_job(export)

      yield success(export)
    end

    private

    def schedule_export_job(export)
      Bim::Bcf::ExportJob.perform_later(export: export,
                                        work_package_ids: query.results.sorted_work_packages.pluck(:id))
    end

    def create_export
      WorkPackages::Export.create user: User.current
    end

    def success(export)
      WorkPackage::Exporter::Delayed
        .new id: export.id
    end
  end
end
