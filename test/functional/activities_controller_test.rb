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

class ActivitiesControllerTest < ActionController::TestCase
  fixtures :all

  def test_project_index
    Journal.delete_all
    project = Project.find(1)
    issue = FactoryGirl.create :issue,
                               status_id: 2,
                               priority_id: 4,
                               author_id: 2,
                               start_date: 1.day.ago.to_date.to_s(:db),
                               due_date: 10.day.from_now.to_date.to_s(:db)

    FactoryGirl.create :work_package_journal,
                       journable_id: issue.id,
                       created_at: 3.days.ago.to_date.to_s(:db),
                       data: FactoryGirl.build(:journal_work_package_journal,
                                               project_id: issue.project_id,
                                               status_id: 1)
    FactoryGirl.create :work_package_journal,
                       journable_id: issue.id,
                       notes: "Some notes with Redmine links: #2, r2.",
                       created_at: 1.days.ago.to_date.to_s(:db),
                       data: FactoryGirl.build(:journal_work_package_journal,
                                               project_id: issue.project_id,
                                               status_id: 2)

    get :index, :id => 1, :with_subprojects => 0
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:events_by_day)

    assert_tag :tag => "h3",
               :content => /#{1.day.ago.to_date.day}/,
               :sibling => { :tag => "dl",
                 :child => { :tag => "dt",
                   :attributes => { :class => /work_package/ },
                   :child => { :tag => "a",
                     :content => /#{ERB::Util.html_escape(IssueStatus.find(2).name)}/
                   }
                 }
               }
  end

  def test_previous_project_index
    issue = Issue.find(1)
    FactoryGirl.create :work_package_journal,
                       journable_id: issue.id,
                       created_at: 3.days.ago.to_date.to_s(:db),
                       data: FactoryGirl.build(:journal_work_package_journal,
                                               project_id: issue.project_id)

    get :index, :id => 1, :from => 3.days.ago.to_date
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:events_by_day)

    assert_tag :tag => "h3",
               :content => /#{3.day.ago.to_date.day}/,
               :sibling => { :tag => "dl",
                 :child => { :tag => "dt",
                   :attributes => { :class => /work_package/ },
                   :child => { :tag => "a",
                     :content => /#{ERB::Util.html_escape(issue.subject)}/
                   }
                 }
               }
  end

  def test_global_index
    issue = Issue.find(1)
    FactoryGirl.create :work_package_journal,
                       journable_id: issue.id,
                       created_at: 3.days.ago.to_date.to_s(:db),
                       data: FactoryGirl.build(:journal_work_package_journal,
                                               project_id: issue.project_id)

    get :index
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:events_by_day)

    assert_tag :tag => "h3",
               :content => /#{3.day.ago.to_date.day}/,
               :sibling => { :tag => "dl",
                 :child => { :tag => "dt",
                   :attributes => { :class => /work_package/ },
                   :child => { :tag => "a",
                     :content => /#{ERB::Util.html_escape(issue.subject)}/
                   }
                 }
               }
  end

  def test_user_index
    issue = Issue.find(1)
    FactoryGirl.create :work_package_journal,
                       journable_id: issue.id,
                       user_id: 2,
                       created_at: 3.days.ago.to_date.to_s(:db),
                       data: FactoryGirl.build(:journal_work_package_journal,
                                               project_id: issue.project_id)

    get :index, :user_id => 2
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:events_by_day)

    assert_tag :tag => "h3",
               :content => /#{3.day.ago.to_date.day}/,
               :sibling => { :tag => "dl",
                 :child => { :tag => "dt",
                   :attributes => { :class => /work_package/ },
                   :child => { :tag => "a",
                     :content => /#{ERB::Util.html_escape(Issue.find(1).subject)}/
                   }
                 }
               }
  end

  def test_index_atom_feed
    issue = Issue.find(11)
    FactoryGirl.create :work_package_journal,
                       journable_id: issue.id,
                       version: 1,
                       data: FactoryGirl.build(:journal_work_package_journal,
                                               project_id: issue.project_id,
                                               subject: issue.subject)
    get :index, :format => 'atom'
    assert_response :success
    assert_template 'common/feed'
    assert_tag :tag => 'entry', :child => {
      :tag => 'link',
      :attributes => {:href => 'http://test.host/work_packages/11'}}
  end

end
