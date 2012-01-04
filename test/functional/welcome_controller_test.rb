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
require 'welcome_controller'

# Re-raise errors caught by the controller.
class WelcomeController; def rescue_action(e) raise e end; end

class WelcomeControllerTest < ActionController::TestCase
  fixtures :projects, :news

  def setup
    @controller = WelcomeController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:news)
    assert_not_nil assigns(:projects)
    assert !assigns(:projects).include?(Project.find(:first, :conditions => {:is_public => false}))
  end

  def test_browser_language
    Setting.default_language = 'en'
    @request.env['HTTP_ACCEPT_LANGUAGE'] = 'fr,fr-fr;q=0.8,en-us;q=0.5,en;q=0.3'
    get :index
    assert_equal :fr, @controller.current_language
  end

  def test_browser_language_alternate
    Setting.default_language = 'en'
    @request.env['HTTP_ACCEPT_LANGUAGE'] = 'zh-TW'
    get :index
    assert_equal :"zh-TW", @controller.current_language
  end

  def test_browser_language_alternate_not_valid
    Setting.default_language = 'en'
    @request.env['HTTP_ACCEPT_LANGUAGE'] = 'fr-CA'
    get :index
    assert_equal :fr, @controller.current_language
  end

  def test_robots
    get :robots
    assert_response :success
    assert_equal 'text/plain', @response.content_type
    assert @response.body.match(%r{^Disallow: /projects/ecookbook/issues\r?$})
  end

  def test_warn_on_leaving_unsaved_turn_on
    user = User.find(2)
    user.pref.warn_on_leaving_unsaved = '1'
    user.pref.save!
    @request.session[:user_id] = 2

    get :index
    assert_tag 'script',
      :attributes => {:type => "text/javascript"},
      :content => %r{new WarnLeavingUnsaved}
  end

  def test_warn_on_leaving_unsaved_turn_off
    user = User.find(2)
    user.pref.warn_on_leaving_unsaved = '0'
    user.pref.save!
    @request.session[:user_id] = 2

    get :index
    assert_no_tag 'script',
      :attributes => {:type => "text/javascript"},
      :content => %r{new WarnLeavingUnsaved}
  end
end
