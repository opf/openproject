# Allows to render global partials, for example.
#
#   render partial: "../views/shared/container"
module Cell::ViewModel::Partial
  def process_options!(options)
    super
    return unless partial = options[:partial]

    parts     = partial.split("/")
    view      = parts.pop
    view      = "_#{view}"
    view     += ".#{options[:formats].first}" if options[:formats]
    prefixes  = self.class.view_paths.collect { |path| ([path] + parts).join("/") }

    options.merge!(view: view, prefixes: prefixes)
  end
end
