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

RSpec.describe Projects::Settings::ModulesController, "menu" do
  let(:current_user) { build_stubbed(:user) }

  let(:project) do
    # project contains wiki by default
    create(:project, enabled_module_names: enabled_modules).tap(&:reload)
  end
  let(:enabled_modules) { %w[wiki] }
  let(:params) { { project_id: project.id } }

  before do
    mock_permissions_for(current_user, &:allow_everything)
    login_as(current_user)
  end

  shared_examples_for "renders the modules show page" do
    it "renders show" do
      get("show", params:)
      expect(response).to be_successful
      expect(response).to render_template "projects/settings/modules/show"
    end
  end

  shared_examples_for "has selector" do |selector|
    render_views

    it do
      get("show", params:)

      expect(response.body).to have_selector selector
    end
  end

  shared_examples_for "has no selector" do |selector|
    render_views

    it do
      get("show", params:)

      expect(response.body).to have_no_selector selector
    end
  end

  describe "show" do
    describe "without wiki" do
      before do
        project.wiki.destroy
        project.reload
      end

      it_behaves_like "renders the modules show page"

      it_behaves_like "has no selector", "#main-menu a.wiki-wiki-menu-item"
    end

    describe "with wiki" do
      describe "without custom wiki menu items" do
        it_behaves_like "has selector", "#main-menu a.wiki-wiki-menu-item"
      end

      describe "with custom wiki menu item" do
        before do
          main_item = create(:wiki_menu_item,
                             navigatable_id: project.wiki.id,
                             name: "example",
                             title: "Example Title")
          create(:wiki_menu_item,
                 navigatable_id: project.wiki.id,
                 name: "sub",
                 title: "Sub Title",
                 parent_id: main_item.id)
        end

        it_behaves_like "renders the modules show page"

        it_behaves_like "has selector", "#main-menu a.wiki-example-menu-item"

        it_behaves_like "has selector", "#main-menu a.wiki-sub-menu-item"
      end
    end

    describe "with activated activity module" do
      let(:enabled_modules) { %w[activity] }

      it_behaves_like "renders the modules show page"

      it_behaves_like "has selector", "#main-menu a.activity-menu-item"
    end

    describe "without activated activity module" do
      it_behaves_like "renders the modules show page"

      it_behaves_like "has no selector", "#main-menu a.activity-menu-item"
    end
  end
end
