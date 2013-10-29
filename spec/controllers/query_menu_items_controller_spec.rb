#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

describe QueryMenuItemsController do
  let(:current_user) { FactoryGirl.create(:admin) }

  let(:project) { FactoryGirl.create :project }
  let(:public_query) { FactoryGirl.create :public_query }

  before do
    # log in user
    User.stub(:current).and_return current_user
  end

  describe '#create' do
    before :each do
      post :create, project_id: project, query_id: public_query
      @query_menu_item = public_query.reload.query_menu_item
    end

    it 'creates a query menu item' do
      @query_menu_item.should be_present
    end

    it 'redirects to the edit action' do
      response.should redirect_to edit_query_menu_item_path(project, public_query, @query_menu_item)
    end
  end
end
