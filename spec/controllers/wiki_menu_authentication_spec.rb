# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe WikiMenuItemsController do
  let(:project) { create(:project, :with_internal_wiki).reload }
  let(:wiki_page) { create(:wiki_page, wiki: project.wiki) }
  let(:params) { { project_id: project.id, id: wiki_page.title } }

  before do
    User.delete_all
    Role.delete_all
  end

  describe "w/ valid auth" do
    it "renders the edit action" do
      admin_user = create(:admin)

      allow(User).to receive(:current).and_return admin_user
      permission_role = create(:project_role, name: "accessgranted", permissions: [:manage_wiki])
      create(:member, principal: admin_user, user: admin_user, project:, roles: [permission_role])

      get("edit", params:)

      expect(response).to be_successful
    end
  end

  describe "w/o valid auth" do
    it "be forbidden" do
      allow(User).to receive(:current).and_return create(:user)

      get("edit", params:)

      expect(response).to have_http_status(:not_found)
    end
  end
end
