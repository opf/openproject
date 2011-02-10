module CodeRay

  # This module holds the Style class and its subclasses.
  #
  # See Plugin.
  module Styles
    extend PluginHost
    plugin_path File.dirname(__FILE__), 'styles'

    class Style
      extend Plugin
      plugin_host Styles

      DEFAULT_OPTIONS = { }

    end

  end

end
