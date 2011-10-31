#-- encoding: UTF-8
class Namespace::TestRoutingController < ApplicationController
  def routed_action
    render_class_and_action
  end
end