# Redmine - project management software
# Copyright (C) 2006-2009  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require File.expand_path('../../test_helper', __FILE__)
require 'reports_controller'

# Re-raise errors caught by the controller.
class ReportsController; def rescue_action(e) raise e end; end


class ReportsControllerTest < ActionController::TestCase
  fixtures :all
  
  def setup
    @controller = ReportsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end
  
  context "GET :issue_report without details" do
    setup do
      get :issue_report, :id => 1
    end

    should_respond_with :success
    should_render_template :issue_report

    [:issues_by_tracker, :issues_by_version, :issues_by_category, :issues_by_assigned_to,
     :issues_by_author, :issues_by_subproject].each do |ivar|
      should_assign_to ivar
      should "set a value for #{ivar}" do
        assert assigns[ivar.to_s].present?
      end
    end
  end

  context "GET :issue_report_details" do
    %w(tracker version priority category assigned_to author subproject).each do |detail|
      context "for #{detail}" do
        setup do
          get :issue_report_details, :id => 1, :detail => detail
        end

        should_respond_with :success
        should_render_template :issue_report_details
        should_assign_to :field
        should_assign_to :rows
        should_assign_to :data
        should_assign_to :report_title
      end
    end

    context "with an invalid detail" do
      setup do
        get :issue_report_details, :id => 1, :detail => 'invalid'
      end

      should_respond_with :redirect
      should_redirect_to('the issue report') {{:controller => 'reports', :action => 'issue_report', :id => 'ecookbook'}}
    end
    
  end
  
end
