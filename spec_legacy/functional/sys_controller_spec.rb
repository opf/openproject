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
require 'sys_controller'

describe SysController, type: :controller do
  fixtures :all

  before do
    Setting.enabled_scm = %w(subversion git)
  end

  describe 'when enabled',
           with_settings: { sys_api_enabled?: true } do

    it 'should projects with repository enabled' do
      get :projects
      assert_response :success
      assert_equal 'application/xml', response.content_type
      assert_select 'projects', children: { count: Project.active.has_module(:repository).count }
    end

    it 'should fetch changesets' do
      expect_any_instance_of(Repository::Subversion).to receive(:fetch_changesets).and_return(true)
      get :fetch_changesets
      assert_response :success
    end

    it 'should fetch changesets one project' do
      expect_any_instance_of(Repository::Subversion).to receive(:fetch_changesets).and_return(true)
      get :fetch_changesets, params: { id: 'ecookbook' }
      assert_response :success
    end

    it 'should fetch changesets unknown project' do
      get :fetch_changesets, params: { id: 'unknown' }
      assert_response 404
    end

    describe 'api key', with_settings: { sys_api_key: 'my_secret_key' } do
      it 'should api key' do
        get :projects, params: { key: 'my_secret_key' }
        assert_response :success
      end

      it 'should wrong key should respond with 403 error' do
        get :projects, params: { key: 'wrong_key' }
        assert_response 403
      end
    end
  end

  describe 'when disabled', with_settings: { sys_api_enabled?: false } do
    it 'should disabled ws should respond with 403 error' do
      get :projects
      assert_response 403
    end
  end
end
