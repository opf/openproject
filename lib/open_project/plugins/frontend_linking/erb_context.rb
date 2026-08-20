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
        # The canonical line-comment copyright header, derived from COPYRIGHT_short so the
        # generated module cannot drift away from the text the linter enforces.
        def copyright_header(sign = "//")
          body = Rails.root.join("COPYRIGHT_short").readlines.map { |line| "#{sign} #{line}".rstrip }

          ["#{sign}-- copyright", *body, "#{sign}++"].join("\n")
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
