#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path('../../../test_helper', __FILE__)

class ApiTest::HttpAcceptAuthTest < ActionDispatch::IntegrationTest
  fixtures :all

  def setup
    Setting.rest_api_enabled = '1'
    Setting.login_required = '1'
  end

  def teardown
    Setting.rest_api_enabled = '0'
    Setting.login_required = '0'
  end

  # Using the NewsController because it's a simple API.
  context "get /news" do
    setup do
      project = Project.find('onlinestore')
      EnabledModule.create(:project => project, :name => 'news')
    end

    context "in :xml format" do
      should_send_correct_authentication_scheme_when_header_authentication_scheme_is_session(:get, "/api/v1/projects/onlinestore/news.xml")
    end

    context "in :json format" do
      should_send_correct_authentication_scheme_when_header_authentication_scheme_is_session(:get, "/api/v1/projects/onlinestore/news.json")
    end
  end
end
