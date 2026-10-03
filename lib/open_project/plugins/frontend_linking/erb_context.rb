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

        def copyright_header
          body = Rails.root.join("COPYRIGHT_short").readlines.map { |line| "// #{line}".rstrip }

          ["//-- copyright", *body, "//++"].join("\n")
        end

        ##
        # Convert a dash and underscore plugin name
        # to an importable module name.
        # e.g., openproject-costs => OpenprojectCosts
        def importable_name(name)
          name
            .tr("-", "_")
            .camelize(:upper)
        end
      end
    end
  end
end
