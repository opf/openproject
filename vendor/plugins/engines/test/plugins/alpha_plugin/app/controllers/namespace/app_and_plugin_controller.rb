class Namespace::AppAndPluginController < ApplicationController
  def an_action
    render_class_and_action 'from alpha_plugin'
  end
end
