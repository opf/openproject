#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

require 'spec_helper'

describe QueryMenuItemsController, :type => :controller do
  let(:current_user) { FactoryGirl.create(:admin) }

  let(:project) { FactoryGirl.create :project }
  let(:public_query) { FactoryGirl.create :public_query }

  before do
    # log in user
    allow(User).to receive(:current).and_return current_user
  end

  describe '#create' do
    before :each do
      post :create, project_id: project, query_id: public_query
      @query_menu_item = public_query.reload.query_menu_item
    end

    it 'creates a query menu item' do
      expect(@query_menu_item).to be_present
    end

    it 'redirects to the query on work_packages#index' do
      expect(response).to redirect_to project_work_packages_path(project, query_id: public_query.id)
    end
  end

  describe '#destroy' do
    let(:query_menu_item) { public_query.create_query_menu_item name: public_query.name, title: public_query.name }

    it 'destroys the query_menu_item' do
      delete :destroy, id: query_menu_item, project_id: project, query_id: public_query
      expect(MenuItems::QueryMenuItem.exists?(query_menu_item.id)).to be_falsey
    end
  end
end
