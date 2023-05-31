OpenProject::Application.configure do
  next unless Rails.env.development?

  config.lookbook.project_name = "OpenProject Design System"
  config.lookbook.project_logo = File.read Rails.root.join('app/assets/images/icon_logo_white.svg')
  config.lookbook.ui_favicon = File.read Rails.root.join('app/assets/images/icon_logo.svg')
  config.lookbook.page_paths = [Rails.root.join("spec/components/docs/").to_s]
  # Show notes first, all other panels next
  config.lookbook.component_paths << Primer::ViewComponents::Engine.root.join("app", "components").to_s
  config.view_component.preview_paths << Primer::ViewComponents::Engine.root.join("previews").to_s
  config.lookbook.preview_inspector.drawer_panels = [:notes, "*"]
  config.lookbook.ui_theme = "blue"

  SecureHeaders::Configuration.named_append(:lookbook) do
    {
      script_src: %w('unsafe-eval' 'unsafe-inline')
    }
  end

  Rails.application.reloader.to_prepare do
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
