#-- encoding: UTF-8
class Namespace::SharedPluginController < ApplicationController
  def an_action
    render_class_and_action 'from beta_plugin'
  end
end
