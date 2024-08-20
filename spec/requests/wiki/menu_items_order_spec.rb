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

RSpec.describe "Menu items order",
               :skip_csrf,
               type: :rails_request do
  shared_let(:admin) { create(:admin) }
  let(:project) { create(:project, enabled_module_names: %w[wiki]) }
  let(:wiki) { project.wiki }

  let!(:item3) { create(:wiki_menu_item, wiki:, title: "3. FAQ") }
  let!(:item2) { create(:wiki_menu_item, wiki:, title: "2. New chapter") }
  let!(:item1) { create(:wiki_menu_item, wiki:, title: "1. Management") }

  before do
    login_as admin
    get project_wiki_path(project, "wiki")
  end

  it "orders the main menu items by title ascending" do
    items = page.all(".wiki-menu--main-item").map { |x| x.text.strip }
    expect(items).to eq ["1. Management", "2. New chapter", "3. FAQ", "Wiki"]
  end
end
