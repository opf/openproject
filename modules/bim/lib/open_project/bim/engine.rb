require 'open_project/plugins'

module OpenProject::Bim
  class Engine < ::Rails::Engine
    engine_name :openproject_bim

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-bim',
             author_url: 'http://openproject.com',
             settings: {
               default: {
               }
             } do

      project_module :bim do
        permission :view_linked_issues,
                   'bim/linked_issues': :index

        permission :manage_bim,
                   'bim/linked_issues': %i[index import perform_import]
      end

      menu :project_menu,
           :bim,
           { controller: '/bim/linked_issues', action: :index },
           caption: :'bim.label_bim',
           param: :project_id,
           icon: 'icon2 icon-backlogs'
    end

    assets %w(bim/bim.css)

    patches %i[WorkPackage]

    extend_api_response(:v3, :work_packages, :work_package_collection) do
      require_relative 'patches/api/v3/export_formats'

      prepend Patches::Api::V3::ExportFormats
    end

    initializer 'bim.register_hooks' do
      # don't use require_dependency to not reload hooks in development mode
      require 'open_project/xls_export/hooks/work_package_hook.rb'
    end

    initializer 'bim.register_mimetypes' do
      Mime::Type.register "application/octet-stream", :bcf unless Mime::Type.lookup_by_extension(:bcf)
    end

    config.to_prepare do
      WorkPackage::Exporter
        .register_for_list(:bcf, OpenProject::Bim::BcfXml::Exporter)
    end
  end
end
