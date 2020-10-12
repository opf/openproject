module OpenProject::XlsExport
  class Engine < ::Rails::Engine
    engine_name :openproject_xls_export

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-xls_export',
             author_url: 'https://www.openproject.com',
             bundled: true

    patches %i[Queries::WorkPackages::Columns::WorkPackageColumn CostReportsController]

    extend_api_response(:v3, :work_packages, :work_package_collection) do
      require_relative 'patches/api/v3/export_formats'

      prepend Patches::API::V3::ExportFormats
    end

    initializer 'xls_export.register_hooks' do
      # don't use require_dependency to not reload hooks in development mode

      require 'open_project/xls_export/hooks/cost_report_hook.rb'

      require 'open_project/xls_export/hooks/work_package_hook.rb'
    end

    initializer 'xls_export.register_mimetypes' do
      next if defined? Mime::XLS

      Mime::Type.register('application/vnd.ms-excel',
                          :xls,
                          %w(application/vnd.ms-excel))
    end

    class_inflection_override('xls' => 'XLS')

    config.to_prepare do
      WorkPackage::Exporter
        .register_for_list(:xls, XlsExport::WorkPackage::Exporter::XLS)
    end
  end
end
