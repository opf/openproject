class AlphaPluginController < ApplicationController
  def an_action
    render_class_and_action
  end
  def action_with_layout
    render_class_and_action(nil, :layout => "plugin_layout")
  end
end
