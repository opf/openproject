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

require 'legacy_spec_helper'
require 'sys_controller'

describe SysController, type: :controller do
  fixtures :all

  before do
    Setting.sys_api_enabled = '1'
    Setting.enabled_scm = %w(Subversion Git)
  end

  it 'should projects with repository enabled' do
    get :projects
    assert_response :success
    assert_equal 'application/xml', response.content_type
    with_options tag: 'projects' do |test|
      test.assert_tag children: { count:  Project.active.has_module(:repository).count }
    end
  end

  it 'should create project repository' do
    assert_nil Project.find(4).repository

    post :create_project_repository, id: 4,
                                     vendor: 'Subversion',
                                     repository: { url: 'file:///create/project/repository/subproject2' }
    assert_response :created

    r = Project.find(4).repository
    assert r.is_a?(Repository::Subversion)
    assert_equal 'file:///create/project/repository/subproject2', r.url
  end

  it 'should fetch changesets' do
    expect_any_instance_of(Repository::Subversion).to receive(:fetch_changesets).and_return(true)
    get :fetch_changesets
    assert_response :success
  end

  it 'should fetch changesets one project' do
    expect_any_instance_of(Repository::Subversion).to receive(:fetch_changesets).and_return(true)
    get :fetch_changesets, id: 'ecookbook'
    assert_response :success
  end

  it 'should fetch changesets unknown project' do
    get :fetch_changesets, id: 'unknown'
    assert_response 404
  end

  it 'should disabled ws should respond with 403 error' do
    with_settings sys_api_enabled: '0' do
      get :projects
      assert_response 403
    end
  end

  it 'should api key' do
    with_settings sys_api_key: 'my_secret_key' do
      get :projects, key: 'my_secret_key'
      assert_response :success
    end
  end

  it 'should wrong key should respond with 403 error' do
    with_settings sys_api_enabled: 'my_secret_key' do
      get :projects, key: 'wrong_key'
      assert_response 403
    end
  end
end
