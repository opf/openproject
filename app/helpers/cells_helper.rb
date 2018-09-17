module CellsHelper
  ##
  # Use this to render cells directly as the view for a controller
  # instead of a standard rails view.
  def render_cell(name, model, opts = {})
    opts[:context] = { controller: self } if is_a? ActionController::Base
    render_options = opts.delete(:render_options) || {}

    cell = cell(name, model, opts)
    rendered = cell.call

    render render_options.merge(text: rendered)
  end

  def rails_cell(name, model, **args)
    args[:context] = {
      controller: try(:controller),
      action_view: self
    }

    cell name, model, args
  end
end
