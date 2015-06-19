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

require File.expand_path('../../spec_helper', __FILE__)

describe ProjectTypesController, type: :controller do
  let(:current_user) { FactoryGirl.create(:admin) }

  before do
    allow(User).to receive(:current).and_return current_user
  end

  describe 'index.html' do
    def fetch
      get 'index'
    end
    it_should_behave_like 'a controller action with require_admin'
  end

  describe 'new.html' do
    def fetch
      get 'new'
    end
    it_should_behave_like 'a controller action with require_admin'
  end

  describe 'create.html' do
    def fetch
      post 'create', project_type: FactoryGirl.build(:project_type).attributes
    end

    def expect_redirect_to
      Regexp.new(project_types_path)
    end
    it_should_behave_like 'a controller action with require_admin'
  end

  describe 'edit.html' do
    def fetch
      FactoryGirl.create(:project_type, id: '1337')
      get 'edit', id: '1337'
    end
    it_should_behave_like 'a controller action with require_admin'
  end

  describe 'update.html' do
    def fetch
      FactoryGirl.create(:project_type, id: '1337')
      put 'update', id: '1337', project_type: { 'name' => 'blubs' }
    end

    def expect_redirect_to
      project_types_path
    end
    it_should_behave_like 'a controller action with require_admin'
  end

  describe 'move.html' do
    def fetch
      FactoryGirl.create(:project_type, id: '1337')
      post 'move', id: '1337', project_type: { move_to: 'highest' }
    end

    def expect_redirect_to
      project_types_path
    end
    it_should_behave_like 'a controller action with require_admin'
  end

  describe 'confirm_destroy.html' do
    def fetch
      FactoryGirl.create(:project_type, id: '1337')
      get 'confirm_destroy', id: '1337'
    end
    it_should_behave_like 'a controller action with require_admin'
  end

  describe 'destroy.html' do
    def fetch
      FactoryGirl.create(:project_type, id: '1337')
      post 'destroy', id: '1337'
    end

    def expect_redirect_to
      project_types_path
    end
    it_should_behave_like 'a controller action with require_admin'
  end
end
