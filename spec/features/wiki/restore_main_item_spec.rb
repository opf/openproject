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

RSpec.describe "Wiki page - restoring main wiki item" do
  let(:project) { create(:project, enabled_module_names: %w[wiki]) }
  let(:user) do
    create(:user, member_with_permissions: { project => %i[view_wiki_pages rename_wiki_pages] })
  end

  before do
    login_as(user)
  end

  it "restores the main item on start" do
    # For some reason, a customer had deleted their wiki start page
    # even though it should be recreated on destruction of the last item
    # This spec ensure the wiki main item is rendered even if no menu item is saved.
    visit project_path(project)

    expect(page)
      .to have_css(".wiki-menu--main-item")

    # Delete all items for some reason
    MenuItems::WikiMenuItem.main_items(project.wiki).destroy_all

    expect(MenuItems::WikiMenuItem.main_items(project.wiki).count).to eq 0

    visit project_path(project)

    expect(page)
      .to have_css(".wiki-menu--main-item")

    expect(MenuItems::WikiMenuItem.main_items(project.wiki).count).to eq 1
  end
end
