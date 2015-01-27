#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
    issue = WorkPackage.find(1)
    journal = FactoryGirl.create :work_package_journal,
                                 journable_id: issue.id
    identifier = "journal-#{journal.id}"

    @request.session[:user_id] = 1
    xhr :get, :edit, id: journal.id
    assert_response :success
    assert_select_rjs :insert, :after, "#{identifier}-notes" do
      assert_select "form[id=#{identifier}-form]"
      assert_select 'textarea'
    end
  end

  def test_post_edit
    issue = WorkPackage.find(1)
    journal = FactoryGirl.create :work_package_journal,
                                 journable_id: issue.id,
                                 data: FactoryGirl.build(:journal_work_package_journal)
    identifier = "journal-#{journal.id}-notes"

    @request.session[:user_id] = 1
    xhr :post, :update, id: journal.id, notes: 'Updated notes'
    assert_response :success
    assert_select_rjs :replace, identifier
    assert_equal 'Updated notes', Journal.find(journal.id).notes
  end

  def test_post_edit_with_empty_notes
    issue = WorkPackage.find(1)
    FactoryGirl.create :work_package_journal,
                       journable_id: issue.id,
                       data: FactoryGirl.build(:journal_work_package_journal)
    journal = FactoryGirl.create :work_package_journal,
                                 journable_id: issue.id,
                                 data: FactoryGirl.build(:journal_work_package_journal)
    identifier = "change-#{journal.id}"

    @request.session[:user_id] = 1
    xhr :post, :update, id: journal.id, notes: ''
    assert_response :success
    assert_select_rjs :remove, identifier
    assert_nil Journal.find_by_id(journal.id)
  end

  def test_index
    get :index, project_id: 1, format: :atom
    assert_response :success
    assert_not_nil assigns(:journals)
    assert_equal 'application/atom+xml', @response.content_type
  end


end
