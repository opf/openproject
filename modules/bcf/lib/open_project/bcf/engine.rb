require 'open_project/plugins'

module OpenProject::Bcf
  class Engine < ::Rails::Engine
    engine_name :openproject_bcf

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-bcf',
             author_url: 'https://openproject.com',
             settings: {
               default: {
               }
             } do

      project_module :bcf do
        permission :view_linked_issues,
                   'bcf/issues': :index

        permission :manage_bcf,
                   'bcf/issues': %i[index import prepare_import perform_import]
      end

      menu :project_menu,
           :bcf,
           { controller: '/bcf/issues', action: :index },
           caption: :'bcf.label_bcf',
           param: :project_id,
           icon: 'icon2 icon-backlogs',
           badge: 'bcf.experimental_badge'
    end

    assets %w(bcf/bcf.css)

    patches %i[WorkPackage]

    patch_with_namespace :BasicData, :SettingSeeder

    extend_api_response(:v3, :work_packages, :work_package) do
      property :bcf,
               exec_context: :decorator,
               getter: ->(*) {
                 issue = represented.bcf_issue
                 bcf = {}
                 bcf[:viewpoints] = issue.viewpoints.map do |viewpoint|
                   {
                     id: viewpoint.snapshot.id,
                     file_name: viewpoint.snapshot.filename
                   }
                 end
                 bcf
               },
               if: ->(*) {
                 represented.bcf_issue.present?
               }
    end

    extend_api_response(:v3, :work_packages, :work_package_collection) do
      require_relative 'patches/api/v3/export_formats'

      prepend Patches::Api::V3::ExportFormats
    end

    initializer 'bcf.register_hooks' do
      # don't use require_dependency to not reload hooks in development mode
      require 'open_project/xls_export/hooks/work_package_hook.rb'
    end

    initializer 'bcf.register_mimetypes' do
      Mime::Type.register "application/octet-stream", :bcf unless Mime::Type.lookup_by_extension(:bcf)
    end

    config.to_prepare do
      WorkPackage::Exporter
        .register_for_list(:bcf, OpenProject::Bcf::BcfXml::Exporter)
    end
  end
end
