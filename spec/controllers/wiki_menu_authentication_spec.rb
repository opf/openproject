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

describe WikiMenuItemsController, type: :controller do
  before do
    User.delete_all
    Role.delete_all

    @project = FactoryBot.create(:project)
    @project.reload # project contains wiki by default

    @params = {}
    @params[:project_id] = @project.id
    page = FactoryBot.create(:wiki_page, wiki: @project.wiki)
    @params[:id] = page.title
  end

  describe 'w/ valid auth' do
    it 'renders the edit action' do
      admin_user = FactoryBot.create(:admin)

      allow(User).to receive(:current).and_return admin_user
      permission_role = FactoryBot.create(:role, name: 'accessgranted', permissions: [:manage_wiki_menu])
      member = FactoryBot.create(:member, principal: admin_user, user: admin_user, project: @project, roles: [permission_role])

      get 'edit', params: @params

      expect(response).to be_successful
    end
  end

  describe 'w/o valid auth' do
    it 'be forbidden' do
      allow(User).to receive(:current).and_return FactoryBot.create(:user)

      get 'edit', params: @params

      expect(response.status).to eq(403) # forbidden
    end
  end
end
