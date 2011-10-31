#-- encoding: UTF-8
class AppAndPluginController < ApplicationController
  def an_action
    render_class_and_action 'from alpha_plugin'
  end
end
