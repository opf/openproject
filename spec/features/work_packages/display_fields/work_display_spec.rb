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

RSpec.describe "Work display", :js do
  include Toasts::Expectations

  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:admin) }
  shared_let(:wiki_page) { create(:wiki_page, wiki: project.wiki) }
  shared_let(:query) do
    create(:query,
           project:,
           user:,
           show_hierarchies: true,
           column_names: %i[id subject estimated_hours])
  end

  before_all do
    set_factory_default(:project, project)
    set_factory_default(:project_with_types, project)
    set_factory_default(:user, user)
  end

  let(:wp_table) { Pages::WorkPackagesTable.new project }
  let(:editor) { Components::WysiwygEditor.new }
  let(:initiator_work_package) { child }

  before do
    WorkPackages::UpdateAncestorsService
      .new(user:, work_package: initiator_work_package)
      .call([:estimated_hours])

    login_as(user)
  end

  shared_examples "work display" do |expected_text:|
    it "work package index" do
      wp_table.visit_query query
      wp_table.expect_work_package_listed child

      wp_table.expect_work_package_with_attributes(
        parent, estimatedTime: expected_text
      )
    end

    it "work package details" do
      visit work_package_path(parent.id)

      expect(page).to have_content("Work\n#{expected_text}")
    end

    it "wiki page workPackageValue:id:estimatedTime macro" do
      visit edit_project_wiki_path(project, wiki_page.id)

      editor.set_markdown("workPackageValue:#{parent.id}:estimatedTime")
      click_on "Save"

      expect(page).to have_css(".wiki-content", text: expected_text)
    end
  end

  context "with both work and total work" do
    let_work_packages(<<~TABLE)
      hierarchy   | work |
      parent      |   1h |
        child     |   3h |
    TABLE

    include_examples "work display", expected_text: "1h·Σ 4h"
  end

  context "with just work" do
    let_work_packages(<<~TABLE)
      hierarchy   | work |
      parent      |   1h |
        child     |   0h |
    TABLE

    include_examples "work display", expected_text: "1h"
  end

  context "with just total work with (parent work 0 h)" do
    let_work_packages(<<~TABLE)
      hierarchy   | work |
      parent      |   0h |
        child     |   3h |
    TABLE

    include_examples "work display", expected_text: "0h·Σ 3h"
  end

  context "with just total work (parent work empty)" do
    let_work_packages(<<~TABLE)
      hierarchy   | work |
      parent      |      |
        child     |   3h |
    TABLE

    include_examples "work display", expected_text: "-·Σ 3h"
  end

  context "with neither work nor total work (both 0 h)" do
    let_work_packages(<<~TABLE)
      hierarchy   | work |
      parent      |   0h |
        child     |   0h |
    TABLE

    include_examples "work display", expected_text: "0h"
  end

  context "with just total work being 0h" do
    let_work_packages(<<~TABLE)
      hierarchy   | work |
      parent      |      |
        child     |   0h |
    TABLE

    include_examples "work display", expected_text: "-·Σ 0h"
  end

  context "with neither work nor total work (both unset)" do
    let_work_packages(<<~TABLE)
      hierarchy   | work |
      parent      |      |
        child     |      |
    TABLE

    include_examples "work display", expected_text: "-"
  end

  describe "link to detailed view" do
    let_work_packages(<<~TABLE)
      hierarchy          | work |
      parent             |   5h |
        child 1          |   0h |
        child 2          |   3h |
          grand child 21 |  12h |
        child 3          |      |
      other one          |   2h |
    TABLE

    # Run UpdateAncestorsService on the grand child to update the whole hierarchy total values
    let(:initiator_work_package) { grand_child21 }

    it "displays a link to a detailed view explaining work calculation" do
      wp_table.visit_query query

      # parent
      expect(page).to have_content("5h·Σ 20h")
      expect(page).to have_link("Σ 20h")
      # child 2
      expect(page).to have_content("3h·Σ 15h")
      expect(page).to have_link("Σ 15h")
    end

    context "when duration format is changed from 'Hours only' to 'Days and hours' in admin" do
      it "displays a link to a detailed view explaining work calculation in days and hours" do
        visit admin_settings_working_days_and_hours_path
        select "Days and hours", from: "Duration format"
        click_on "Apply changes"
        expect_and_dismiss_toaster(message: "Successful update.")

        wp_table.visit_query query

        # parent
        expect(page).to have_content("5h·Σ 2d 4h")
        expect(page).to have_link("Σ 2d 4h")
        # child 2
        expect(page).to have_content("3h·Σ 1d 7h")
        expect(page).to have_link("Σ 1d 7h")
      end
    end

    context "when clicking the link of a top parent" do
      before do
        visit work_package_path(parent)
      end

      it "shows a work package table with a parent filter to list the direct children" do
        click_on("Σ 20h")

        wp_table.expect_work_package_count(4)
        wp_table.expect_work_package_listed(parent, child1, child2, child3)
        within(:table) do
          expect(page).to have_columnheader("Work")
          expect(page).to have_columnheader("Remaining work")
        end
      end
    end

    context "when clicking the link of an intermediate parent" do
      before do
        visit work_package_path(child2)
      end

      it "shows also all ancestors in the work package table" do
        expect(page).to have_content("Work\n3h·Σ 15h")
        click_on("Σ 15h")

        wp_table.expect_work_package_count(3)
        wp_table.expect_work_package_listed(parent, child2, grand_child21)
      end
    end
  end
end
