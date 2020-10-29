require "rails/railtie"
require "cell/rails"

module Cell
  class Railtie < Rails::Railtie

    config.cells = ActiveSupport::OrderedOptions.new

    initializer("cells.attach_router") do |app|
      ViewModel.class_eval do
        include app.routes.url_helpers # TODO: i hate this, make it better in Rails.
      end
    end

    # ruthlessly stolen from the zurb-foundation gem.
    initializer "cells.update_asset_paths" do |app|
      # Add Rails.root to view_paths
      Cell::ViewModel.view_paths = [Rails.root.join("app", "cells")]

      Array(app.config.cells.with_assets).each do |cell_class|
        # puts "@@@@@ #{cell_class.camelize.constantize.prefixes}"
        app.config.assets.paths += cell_class.camelize.constantize.prefixes # Song::Cell.prefixes
      end
    end

    initializer "cells.rails_extensions" do |app|
      ActiveSupport.on_load(:action_controller) do
        self.class_eval do
          include ::Cell::RailsExtensions::ActionController
        end
      end

      ActiveSupport.on_load(:action_view) do
        self.class_eval do
          include ::Cell::RailsExtensions::ActionView
        end
      end

      require "cell/rails/collection"
      require "cell/rails/constant_for"

      Cell::Collection.send :include, Cell::RailsExtension::Collection
      Cell::ViewModel.send :include, Cell::RailsExtension::ConstantFor
    end

    initializer "cells.include_default_helpers" do
      # include asset helpers (image_path, font_path, ect)
      ViewModel.class_eval do
        include ActionView::Helpers::FormHelper # includes ActionView::Helpers::UrlHelper, ActionView::Helpers::FormTagHelper
        include ::Cell::RailsExtensions::HelpersAreShit

        require "cell/helper/asset_helper"
        include Cell::Helper::AssetHelper

        # set VM#cache_store, etc.
        include RailsExtensions::ViewModel
      end
    end

    IncludeTemplateModules = ->(app) do
      return if app.config.cells.include_template_engine == false

      # yepp, this is happening. saves me a lot of coding in each extension.
      ViewModel.send(:include, Cell::Erb)    if Cell.const_defined?(:Erb, false)
      ViewModel.send(:include, Cell::Haml)   if Cell.const_defined?(:Haml, false)
      ViewModel.send(:include, Cell::Hamlit) if Cell.const_defined?(:Hamlit, false)
      ViewModel.send(:include, Cell::Slim)   if Cell.const_defined?(:Slim, false)
    end

    initializer( "cells.include_template_module", after: "cells.include_default_helpers", &IncludeTemplateModules)

    initializer("cells.development") do |app|
      if Rails.env == "development"
        require "cell/development"
        ViewModel.send(:include, Development)
      end
    end

    rake_tasks do
      load "tasks/cells.rake"
    end
  end
end
