module CellsHelper
  def rails_cell(name, model, **args)
    args[:context] = {
      controller: try(:controller),
      action_view: self
    }

    cell name, model, args
  end
end
