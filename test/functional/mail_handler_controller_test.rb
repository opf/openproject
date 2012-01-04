#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../test_helper', __FILE__)
require 'mail_handler_controller'

# Re-raise errors caught by the controller.
class MailHandlerController; def rescue_action(e) raise e end; end

class MailHandlerControllerTest < ActionController::TestCase
  fixtures :users, :projects, :enabled_modules, :roles, :members, :member_roles, :issues, :issue_statuses, :trackers, :enumerations

  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures/mail_handler'

  def setup
    @controller = MailHandlerController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end

  def test_should_create_issue
    # Enable API and set a key
    Setting.mail_handler_api_enabled = 1
    Setting.mail_handler_api_key = 'secret'

    post :index, :key => 'secret', :email => IO.read(File.join(FIXTURES_PATH, 'ticket_on_given_project.eml'))
    assert_response 201
  end

  def test_should_not_allow
    # Disable API
    Setting.mail_handler_api_enabled = 0
    Setting.mail_handler_api_key = 'secret'

    post :index, :key => 'secret', :email => IO.read(File.join(FIXTURES_PATH, 'ticket_on_given_project.eml'))
    assert_response 403
  end
end
