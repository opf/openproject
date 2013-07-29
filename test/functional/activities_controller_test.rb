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
                     :content => /#{ERB::Util.html_escape(Issue.find(1).subject)}/
                   }
                 }
               }
  end

  def test_global_index
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
                     :content => /#{ERB::Util.html_escape(Issue.find(1).subject)}/
                   }
                 }
               }
  end

  def test_user_index
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
    get :index, :format => 'atom'
    assert_response :success
    assert_template 'common/feed'
    assert_tag :tag => 'entry', :child => {
      :tag => 'link',
      :attributes => {:href => 'http://test.host/work_packages/11'}}
  end

end
