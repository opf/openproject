class Namespace::SharedPluginController < ApplicationController
  def an_action
    render_class_and_action 'from alpha_plugin'
  end
end
