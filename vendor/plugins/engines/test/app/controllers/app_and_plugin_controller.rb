#-- encoding: UTF-8
class AppAndPluginController < ApplicationController
  def an_action
    render_class_and_action 'from app'
  end
end
