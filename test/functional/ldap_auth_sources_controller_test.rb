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

require File.expand_path('../../test_helper', __FILE__)

class LdapAuthSourcesControllerTest < ActionController::TestCase
  fixtures :all

  def setup
    super
    @request.session[:user_id] = 1
  end

  context "get :new" do
    setup do
      get :new
    end

    should_assign_to :auth_source
    should respond_with :success
    should render_template :new

    should "initilize a new AuthSource" do
      assert_equal LdapAuthSource, assigns(:auth_source).class
      assert assigns(:auth_source).new_record?
    end
  end
end
