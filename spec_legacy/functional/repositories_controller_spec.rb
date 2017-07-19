#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
require_relative '../legacy_spec_helper'
require 'repositories_controller'

describe RepositoriesController, type: :controller do
  render_views

  # We load legacy fixtures and repository
  # but now have to override them with the temporary subversion
  # repository, as the filesystem repository has been stripped.
  fixtures :all

  before do
    unless repository_configured?('subversion')
      skip 'Subversion test repository NOT FOUND. Skipping functional tests !!!'
    end
  end

  let(:project) { Project.find(1) }

  before do
    User.current = nil
  end

  it 'should revisions' do
    get :revisions, params: { project_id: 1 }
    assert_response :success
    assert_template 'revisions'
    refute_nil assigns(:changesets)
  end

  it 'should revision' do
    get :revision, params: { project_id: 1, rev: 1 }
    assert_response :success
    refute_nil assigns(:changeset)
    assert_equal '1', assigns(:changeset).revision
  end

  it 'should revision with before nil and after normal' do
    get :revision, params: { project_id: 1, rev: 1 }
    assert_response :success
    assert_template 'revision'
    assert_select('ul',
                  {
                    attributes: { class: 'toolbar-items' },
                    descendant: {
                      tag: 'a',
                      attributes: {
                        href: @controller.url_for(
                          only_path: true,
                          controller: 'repositories',
                          action: 'revision',
                          project_id: 'ecookbook',
                          rev: '0'
                        )
                      }
                    }
                  }, false)
    assert_select 'ul',
                  attributes: { class: 'toolbar-items' },
                  descendant: {
                    tag: 'a',
                    attributes: {
                      href: @controller.url_for(
                        only_path: true,
                        controller: 'repositories',
                        action: 'revision',
                        project_id: 'ecookbook',
                        rev: '2'
                      )
                    }
                  }
  end

  it 'should graph commits per month' do
    get :graph, params: { project_id: 1, graph: 'commits_per_month' }
    assert_response :success
    assert_equal 'image/svg+xml', response.content_type
  end

  it 'should committers' do
    session[:user_id] = 2
    # add a commit with an unknown user
    Changeset.create!(
      repository: Project.find(1).repository,
      committer: 'foo',
      committed_on: Time.now,
      revision: 100,
      comments: 'Committed by foo.'
    )

    get :committers, params: { project_id: 1 }
    assert_response :success
    assert_template 'committers'

    assert_select 'td',
                  content: 'foo',
                  sibling: {
                    tag: 'td',
                    child: {
                      tag: 'select',
                      attributes: { name: %r{^committers\[\d+\]\[\]$} }
                    }
                  }
    assert_select('td',
                  {
                    content: 'foo',
                    sibling: {
                      tag: 'td',
                      descendant: { tag: 'option', attributes: { selected: 'selected' } }
                    }
                  }, false)
  end

  it 'should map committers' do
    session[:user_id] = 2
    # add a commit with an unknown user
    c = Changeset.create!(
      repository: Project.find(1).repository,
      committer: 'foo',
      committed_on: Time.now,
      revision: 100,
      comments: 'Committed by foo.'
    )
    assert_no_difference "Changeset.where('user_id = 3').count" do
      post :committers,
           params: {
             project_id: 1,
             committers: { '0' => ['foo', '2'],
                           '1' => ['dlopper', '3'] }
           }
      assert_redirected_to '/projects/ecookbook/repository/committers'
      assert_equal User.find(2), c.reload.user
    end
  end
end
