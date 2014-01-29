# Prevent load-order problems in case openproject-plugins is listed after a plugin in the Gemfile
# or not at all
require 'open_project/plugins'

module OpenProject::PdfExport
  class Engine < ::Rails::Engine
    engine_name :openproject_pdf_export

    include OpenProject::Plugins::ActsAsOpEngine

    config.to_prepare do
      unless Redmine::Plugin.registered_plugins.include?(:openproject_pdf_export)
        Redmine::Plugin.register :openproject_pdf_export do
          name 'OpenProject PDF Export'
          author 'Finn GmbH'
          description 'A plugin for exporting anything (including camels) as PDFs'

          url 'https://www.openproject.org/projects/plugin-pdf_export'
          author_url 'http://www.finn.de/'

          version OpenProject::Backlogs::VERSION

          requires_openproject ">= 3.0.0pre13"

          menu :admin_menu,
            :export_card_configurations,
            {:controller => '/export_card_configurations', :action => 'index'},
            {:caption    => :'label_export_card_configuration_plural', :html => {:class => "icon2 icon-tracker"}}
        end
      end
    end

  end
end
