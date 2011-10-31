#-- encoding: UTF-8
require File.dirname(__FILE__) + '/../test_helper'

class ExceptionNotificationCompatibilityTest < ActionController::TestCase
  ExceptionNotifier.exception_recipients = %w(joe@schmoe.com bill@schmoe.com)
  class SimpleController < ApplicationController
    include ExceptionNotifiable
    local_addresses.clear
    consider_all_requests_local = false
    def index
      begin
        raise "Fail!"
      rescue Exception => e
        rescue_action_in_public(e)
      end
    end
  end
  
  def setup
    @controller = SimpleController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_should_work
    assert_nothing_raised do
      get :index
    end
  end
end