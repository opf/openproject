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

class ContextMenusControllerTest < ActionController::TestCase
  fixtures :all

  def test_context_menu_one_issue
    @request.session[:user_id] = 2
    get :issues, :ids => [1]
    assert_response :success
    assert_template 'context_menu'
    assert_tag :tag => 'a', :content => 'Edit',
                            :attributes => { :href => '/issues/1/edit',
                                             :class => 'icon-edit' }
    assert_tag :tag => 'a', :content => 'Closed',
                            :attributes => { :href => '/issues/bulk_edit?ids%5B%5D=1&amp;issue%5Bstatus_id%5D=5',
                                             :class => '' }
    assert_tag :tag => 'a', :content => 'Immediate',
                            :attributes => { :href => '/issues/bulk_edit?ids%5B%5D=1&amp;issue%5Bpriority_id%5D=8',
                                             :class => '' }
    # Versions
    assert_tag :tag => 'a', :content => '2.0',
                            :attributes => { :href => '/issues/bulk_edit?ids%5B%5D=1&amp;issue%5Bfixed_version_id%5D=3',
                                             :class => '' }
    assert_tag :tag => 'a', :content => 'eCookbook Subproject 1 - 2.0',
                            :attributes => { :href => '/issues/bulk_edit?ids%5B%5D=1&amp;issue%5Bfixed_version_id%5D=4',
                                             :class => '' }

    assert_tag :tag => 'a', :content => 'Dave Lopper',
                            :attributes => { :href => '/issues/bulk_edit?ids%5B%5D=1&amp;issue%5Bassigned_to_id%5D=3',
                                             :class => '' }
    assert_tag :tag => 'a', :content => 'Duplicate',
                            :attributes => { :href => '/projects/ecookbook/issues/1/copy',
                                             :class => 'icon-duplicate' }
    assert_tag :tag => 'a', :content => 'Copy',
                            :attributes => { :href => '/issues/move/new?copy_options%5Bcopy%5D=t&amp;ids%5B%5D=1',
                                             :class => 'icon-copy' }
    assert_tag :tag => 'a', :content => 'Move',
                            :attributes => { :href => '/issues/move/new?ids%5B%5D=1',
                                             :class => 'icon-move' }
    assert_tag :tag => 'a', :content => 'Delete',
                            :attributes => { :href => '/issues/destroy?ids%5B%5D=1',
                                             :class => 'icon-del' }
  end

  def test_context_menu_one_issue_by_anonymous
    get :issues, :ids => [1]
    assert_response :success
    assert_template 'context_menu'
    assert_tag :tag => 'a', :content => 'Delete',
                            :attributes => { :href => '#',
                                             :class => 'icon-del disabled' }
  end

  def test_context_menu_multiple_issues_of_same_project
    @request.session[:user_id] = 2
    get :issues, :ids => [1, 2]
    assert_response :success
    assert_template 'context_menu'
    assert_not_nil assigns(:issues)
    assert_equal [1, 2], assigns(:issues).map(&:id).sort

    ids = assigns(:issues).map(&:id).map {|i| "ids%5B%5D=#{i}"}.join('&amp;')
    assert_tag :tag => 'a', :content => 'Edit',
                            :attributes => { :href => "/issues/bulk_edit?#{ids}",
                                             :class => 'icon-edit' }
    assert_tag :tag => 'a', :content => 'Closed',
                            :attributes => { :href => "/issues/bulk_edit?#{ids}&amp;issue%5Bstatus_id%5D=5",
                                             :class => '' }
    assert_tag :tag => 'a', :content => 'Immediate',
                            :attributes => { :href => "/issues/bulk_edit?#{ids}&amp;issue%5Bpriority_id%5D=8",
                                             :class => '' }
    assert_tag :tag => 'a', :content => 'Dave Lopper',
                            :attributes => { :href => "/issues/bulk_edit?#{ids}&amp;issue%5Bassigned_to_id%5D=3",
                                             :class => '' }
    assert_tag :tag => 'a', :content => 'Copy',
                            :attributes => { :href => "/issues/move/new?copy_options%5Bcopy%5D=t&amp;#{ids}",
                                             :class => 'icon-copy' }
    assert_tag :tag => 'a', :content => 'Move',
                            :attributes => { :href => "/issues/move/new?#{ids}",
                                             :class => 'icon-move' }
    assert_tag :tag => 'a', :content => 'Delete',
                            :attributes => { :href => "/issues/destroy?#{ids}",
                                             :class => 'icon-del' }
  end

  def test_context_menu_multiple_issues_of_different_projects
    @request.session[:user_id] = 2
    get :issues, :ids => [1, 2, 6]
    assert_response :success
    assert_template 'context_menu'
    assert_not_nil assigns(:issues)
    assert_equal [1, 2, 6], assigns(:issues).map(&:id).sort

    ids = assigns(:issues).map(&:id).map {|i| "ids%5B%5D=#{i}"}.join('&amp;')
    assert_tag :tag => 'a', :content => 'Edit',
                            :attributes => { :href => "/issues/bulk_edit?#{ids}",
                                             :class => 'icon-edit' }
    assert_tag :tag => 'a', :content => 'Closed',
                            :attributes => { :href => "/issues/bulk_edit?#{ids}&amp;issue%5Bstatus_id%5D=5",
                                             :class => '' }
    assert_tag :tag => 'a', :content => 'Immediate',
                            :attributes => { :href => "/issues/bulk_edit?#{ids}&amp;issue%5Bpriority_id%5D=8",
                                             :class => '' }
    assert_tag :tag => 'a', :content => 'John Smith',
                            :attributes => { :href => "/issues/bulk_edit?#{ids}&amp;issue%5Bassigned_to_id%5D=2",
                                             :class => '' }
    assert_tag :tag => 'a', :content => 'Delete',
                            :attributes => { :href => "/issues/destroy?#{ids}",
                                             :class => 'icon-del' }
  end

  def test_context_menu_issue_visibility
    get :issues, :ids => [1, 4]
    assert_response :success
    assert_template 'context_menu'
    assert_equal [1], assigns(:issues).collect(&:id)
  end
end
