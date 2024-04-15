module OpenProject::XlsExport
  class Engine < ::Rails::Engine
    engine_name :openproject_xls_export

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-xls_export",
             author_url: "https://www.openproject.org",
             bundled: true

    config.to_prepare do
      OpenProject::XlsExport::Hooks::WorkPackageHook
    end

    initializer "xls_export.register_mimetypes" do
      next if defined? Mime::XLS

      Mime::Type.register("application/vnd.ms-excel",
                          :xls,
                          %w(application/vnd.ms-excel))
    end

    class_inflection_override("xls" => "XLS")

    config.to_prepare do
      ::Exports::Register.register do
        list(::WorkPackage, XlsExport::WorkPackage::Exporter::XLS)
        list(::Project, XlsExport::Project::Exporter::XLS)
      end
    end
  end
end
