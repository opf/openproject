module OpenProject
  module Plugins
    module FrontendLinking
      class ErbContext

        def initialize(plugins)
          @plugins = plugins.keys.map { |name, _| [name, importable_name(name)] }
        end

        def frontend_plugins
          @plugins
        end

        def get_binding
          binding
        end

        ##
        # Convert a dash and underscore plugin name
        # to an importable module name.
        # e.g., openproject-costs => OpenprojectCosts
        def importable_name(name)
          name
            .tr('-', '_')
            .camelize(:upper)
        end
      end
    end
  end
end
