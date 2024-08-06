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
require "features/page_objects/notification"
require "features/work_packages/shared_contexts"
require "features/work_packages/work_packages_page"

RSpec.describe "Query menu items", :js, :with_cuprite do
  let(:user) { create(:admin) }
  let(:project) { create(:project) }
  let(:work_packages_page) { WorkPackagesPage.new(project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:notification) { PageObjects::Notifications.new(page) }
  let(:query_title) { Components::WorkPackages::QueryTitle.new }
  let(:status) { create(:status) }

  def visit_index_page(query)
    work_packages_page.select_query(query)
  end

  before do
    status

    allow(User).to receive(:current).and_return user
  end

  context "with identical names" do
    let(:query_a) do
      create(:query_with_view_work_packages_table,
             public: true,
             name: "some query.",
             project:)
    end
    let(:query_b) do
      create(:query_with_view_work_packages_table,
             public: true,
             name: query_a.name,
             project:)
    end

    it "can be shown" do
      visit_index_page(query_a)

      wp_table.visit_query query_a
      wp_table.expect_title query_a.name
    end
  end

  context "with dots in their name" do
    let(:query) do
      create(:query_with_view_work_packages_table,
             public: true,
             name: "OP 3.0",
             project:)
    end

    after do
      work_packages_page.ensure_loaded
    end

    it "can be added" do
      visit_index_page(query)

      click_on "More actions"
      click_on I18n.t("js.toolbar.settings.visibility_settings")
      check "Favored"
      click_on "Save"

      notification.expect_success("Successful update")
      expect(page).to have_css(".op-submenu--item", text: query.name)
    end
  end

  describe "renaming a menu item" do
    let!(:query_a) do
      create(:query_with_view_work_packages_table,
             public: true,
             name: "bbbb",
             project:,
             user:)
    end
    let!(:query_b) do
      create(:query_with_view_work_packages_table,
             public: true,
             name: "zzzz",
             project:,
             user:)
    end

    let(:new_name) { "aaaaa" }

    before do
      visit_index_page(query_b)

      query_title.expect_title "zzzz"
      input = query_title.input_field
      input.set new_name
      input.send_keys :return
    end

    after do
      work_packages_page.ensure_loaded
    end

    it "displaying a success message" do
      notification.expect_success("Successful update")
    end

    it "is renaming and reordering the list" do
      # Renaming the query should also reorder the queries.  As it is renamed
      # from zzzz to aaaa, it should now be the first query menu item.
      expect(page).to have_css(".op-submenu--items li:first-child", text: new_name)
    end
  end
end
