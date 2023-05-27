OpenProject::Application.configure do
  config.view_component.generate.preview_path = Rails.root.join("spec/components/previews").to_s
  config.view_component.preview_paths << Rails.root.join("spec/components/previews").to_s
  config.lookbook.project_name = "OpenProject Lookbook"
  config.lookbook.page_paths = [Rails.root.join("spec/components/docs/").to_s]
  config.lookbook.ui_theme = "blue"

  config.to_prepare do
    next unless Rails.env.development?
    SecureHeaders::Configuration.named_append(:lookbook) do
      {
        script_src: %w('unsafe-eval' 'unsafe-inline')
      }
    end

    module LookbookCspExtender
      extend ActiveSupport::Concern

      included do
        before_action do
          use_content_security_policy_named_append :lookbook
        end
      end
    end

    [
      Lookbook::ApplicationController,
      Lookbook::PreviewController,
      Lookbook::PreviewsController,
      Lookbook::PageController,
      Lookbook::PagesController,
      Lookbook::InspectorController,
      Lookbook::EmbedsController,
    ].each do |controller|
      controller.include LookbookCspExtender
    end
  end
end
