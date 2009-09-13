module Engines
  class Plugin
    class Loader < Rails::Plugin::Loader    
      protected    
        def register_plugin_as_loaded(plugin)
          super plugin
          Engines.plugins << plugin
        end    
    end
  end
end