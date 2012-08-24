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
require File.expand_path('../../../test_helper', __FILE__)
require 'issues/reports_controller'

# Re-raise errors caught by the controller.
class Issues::ReportsController; def rescue_action(e) raise e end; end


class Issues::ReportsControllerTest < ActionController::TestCase
  fixtures :all

  def setup
    @controller = Issues::ReportsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end

  context "GET :issue_report without details" do
    setup do
      get :report, :project_id => 1
    end

    should respond_with :success
    should render_template :report

    [:issues_by_tracker, :issues_by_version, :issues_by_category, :issues_by_assigned_to,
     :issues_by_author, :issues_by_subproject].each do |ivar|
      should assign_to ivar
      should "set a value for #{ivar}" do
        assert assigns[ivar.to_s].present?
      end
    end
  end

  context "GET :issue_report_details" do
    %w(tracker version priority category assigned_to author subproject).each do |detail|
      context "for #{detail}" do
        setup do
          get :report_details, :project_id => 1, :detail => detail
        end

        should respond_with :success
        should render_template :report_details
        should assign_to :field
        should assign_to :rows
        should assign_to :data
        should assign_to :report_title
      end
    end

    context "with an invalid detail" do
      setup do
        get :report_details, :project_id => 1, :detail => 'invalid'
      end

      should respond_with :redirect
      should redirect_to('the issue report') { report_project_issues_path('ecookbook') }
    end

  end

end
