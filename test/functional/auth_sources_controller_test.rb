#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path('../../test_helper', __FILE__)

# Remove to_s on the TreeNode. This would cause an error on Ruby 1.9 as the
# method has a bug preventing it to return strings. It is implicitly called by
# shoulda during an inspect on Ruby 1.9 only. The bug is reported at
# http://rubyforge.org/tracker/index.php?func=detail&aid=29435&group_id=1215&atid=4793
Tree::TreeNode.class_eval {remove_method :to_s}

class AuthSourcesControllerTest < ActionController::TestCase
  fixtures :all

  def setup
    @request.session[:user_id] = 1
  end

  context "get :index" do
    setup do
      get :index
    end

    should_assign_to :auth_sources
    should_assign_to :auth_source_pages
    should_respond_with :success
    should_render_template :index
  end

  context "get :new" do
    setup do
      get :new
    end

    should_assign_to :auth_source
    should_respond_with :success
    should_render_template :new

    should "initilize a new AuthSource" do
      assert_equal AuthSource, assigns(:auth_source).class
      assert assigns(:auth_source).new_record?
    end
  end

  context "post :create" do
    setup do
      post :create, :auth_source => {:name => 'Test'}
    end

    should_respond_with :redirect
    should_redirect_to("index") {{:action => 'index'}}
    should_set_the_flash_to /success/i
  end

  context "get :edit" do
    setup do
      @auth_source = AuthSource.generate!(:name => 'TestEdit')
      get :edit, :id => @auth_source.id
    end

    should_assign_to(:auth_source) {@auth_source}
    should_respond_with :success
    should_render_template :edit
  end

  context "post :update" do
    setup do
      @auth_source = AuthSource.generate!(:name => 'TestEdit')
      post :update, :id => @auth_source.id, :auth_source => {:name => 'TestUpdate'}
    end

    should_respond_with :redirect
    should_redirect_to("index") {{:action => 'index'}}
    should_set_the_flash_to /update/i
  end

  context "post :destroy" do
    setup do
      @auth_source = AuthSource.generate!(:name => 'TestEdit')
    end

    context "without users" do
      setup do
        post :destroy, :id => @auth_source.id
      end

      should_respond_with :redirect
      should_redirect_to("index") {{:action => 'index'}}
      should_set_the_flash_to /deletion/i
    end

    context "with users" do
      setup do
        User.generate!(:auth_source => @auth_source)
        post :destroy, :id => @auth_source.id
      end

      should_respond_with :redirect
      should "not destroy the AuthSource" do
        assert AuthSource.find(@auth_source.id)
      end
    end
  end
end
