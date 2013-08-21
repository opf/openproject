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
require 'journals_controller'

# Re-raise errors caught by the controller.
class JournalsController; def rescue_action(e) raise e end; end

class JournalsControllerTest < ActionController::TestCase
  fixtures :all

  def setup
    super
    @controller = JournalsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end

  def test_get_edit
    issue = Issue.find(1)
    journal = FactoryGirl.create :work_package_journal,
                                 journable_id: issue.id
    identifier = "journal-#{journal.id}"

    @request.session[:user_id] = 1
    xhr :get, :edit, :id => journal.id
    assert_response :success
    assert_select_rjs :insert, :after, "#{identifier}-notes" do
      assert_select "form[id=#{identifier}-form]"
      assert_select 'textarea'
    end
  end

  def test_post_edit
    issue = Issue.find(1)
    journal = FactoryGirl.create :work_package_journal,
                                 journable_id: issue.id,
                                 data: FactoryGirl.build(:journal_work_package_journal)
    identifier = "journal-#{journal.id}-notes"

    @request.session[:user_id] = 1
    xhr :post, :update, :id => journal.id, :notes => 'Updated notes'
    assert_response :success
    assert_select_rjs :replace, identifier
    assert_equal 'Updated notes', Journal.find(journal.id).notes
  end

  def test_post_edit_with_empty_notes
    issue = Issue.find(1)
    FactoryGirl.create :work_package_journal,
                       journable_id: issue.id,
                       data: FactoryGirl.build(:journal_work_package_journal)
    journal = FactoryGirl.create :work_package_journal,
                                 journable_id: issue.id,
                                 data: FactoryGirl.build(:journal_work_package_journal)
    identifier = "change-#{journal.id}"

    @request.session[:user_id] = 1
    xhr :post, :update, :id => journal.id, :notes => ''
    assert_response :success
    assert_select_rjs :remove, identifier
    assert_nil Journal.find_by_id(journal.id)
  end

  def test_index
    get :index, :project_id => 1, :format => :atom
    assert_response :success
    assert_not_nil assigns(:journals)
    assert_equal 'application/atom+xml', @response.content_type
  end


end
