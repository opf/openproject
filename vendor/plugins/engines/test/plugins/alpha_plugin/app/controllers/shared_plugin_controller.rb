#-- encoding: UTF-8
class SharedEngineController < ApplicationController
  def an_action
    render_class_and_action 'from alpha_engine'
  end
end
