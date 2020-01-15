#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe ColorsController, type: :controller do
  let(:current_user) { FactoryBot.create(:admin) }

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
      post 'create', params: { color: FactoryBot.build(:color).attributes }
    end

    def expect_redirect_to
      Regexp.new(colors_path)
    end
    it_should_behave_like 'a controller action with require_admin'
  end

  describe 'edit.html' do
    def fetch
      @available_color = FactoryBot.create(:color, id: '1337')
      get 'edit', params: { id: '1337' }
    end
    it_should_behave_like 'a controller action with require_admin'
  end

  describe 'update.html' do
    def fetch
      @available_color = FactoryBot.create(:color, id: '1337')
      put 'update', params: { id: '1337', color: { 'name' => 'blubs' } }
    end

    def expect_redirect_to
      colors_path
    end
    it_should_behave_like 'a controller action with require_admin'
  end

  describe 'confirm_destroy.html' do
    def fetch
      @available_color = FactoryBot.create(:color, id: '1337')
      get 'confirm_destroy', params: { id: '1337' }
    end
    it_should_behave_like 'a controller action with require_admin'
  end

  describe 'destroy.html' do
    def fetch
      @available_color = FactoryBot.create(:color, id: '1337')
      post 'destroy', params: { id: '1337' }
    end

    def expect_redirect_to
      colors_path
    end
    it_should_behave_like 'a controller action with require_admin'
  end
end
