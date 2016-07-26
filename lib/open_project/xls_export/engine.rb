module OpenProject::XlsExport
  class Engine < ::Rails::Engine
    engine_name :openproject_xls_export

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-xls_export',
             :author_url => 'http://finn.de/',
             :requires_openproject => '>= 4.0.0'

    patches [:WorkPackagesController, :QueryColumn]
    # disabled since not yet migrated: :CostReportsController

    initializer 'xls_export.mixins' do
      require_relative 'patches/api/experimental/export_formats'

      Api::Experimental::WorkPackagesController.prepend OpenProject::XlsExport::ExportFormats
    end

    initializer 'xls_export.register_hooks' do
      # don't use require_dependency to not reload hooks in development mode

      # disabled since not yet migrated
      # require 'open_project/xls_export/hooks/cost_report_hook.rb'

      require 'open_project/xls_export/hooks/work_package_hook.rb'
    end

    initializer 'xls_export.register_mimetypes' do
      Mime::Type.register('application/vnd.ms-excel',
                          :xls,
                          %w(application/vnd.ms-excel)) unless defined? Mime::XLS
    end
  end
end
