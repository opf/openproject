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

RSpec.describe "Wysiwyg child pages spec", :js do
  let(:project) do
    create(:project,
           enabled_module_names: %w[wiki])
  end
  let(:editor) { Components::WysiwygEditor.new }
  let(:role) { create(:project_role, permissions: %i[view_wiki_pages edit_wiki_pages]) }
  let(:user) do
    create(:user, member_with_roles: { project => role })
  end

  let(:wiki_page) do
    create(:wiki_page,
           title: "Test",
           text: "# My page")
  end

  let(:parent_page) do
    create(:wiki_page,
           title: "Parent page",
           text: "# parent page")
  end

  let(:child_page) do
    create(:wiki_page,
           title: "Child page",
           text: "# child page")
  end

  before do
    login_as(user)

    project.wiki.pages << wiki_page
    project.wiki.pages << parent_page
    project.wiki.pages << child_page
    child_page.parent = parent_page
    child_page.save!
    project.wiki.save!
    login_as(user)
  end

  describe "in wikis" do
    describe "creating a wiki page" do
      before do
        visit edit_project_wiki_path(project, :test)
      end

      it "can add and edit an child pages widget" do
        editor.in_editor do |_container, editable|
          expect(editable).to have_css("h1", text: "My page")

          editor.insert_macro "Links to child pages"

          # Find widget, click to show toolbar
          placeholder = find(".op-uc-placeholder", text: "Links to child pages")

          # Placeholder states `this page` and no `Include parent`
          expect(placeholder).to have_text("this page")
          expect(placeholder).to have_no_text("Include parent")

          # Edit widget and cancel again
          placeholder.click
          page.find(".ck-balloon-panel .ck-button", visible: :all, text: "Edit").click
          expect(page).to have_css(".spot-modal")
          expect(page).to have_field("selected-page", with: "")
          find(".spot-modal--cancel-button").click

          # Edit widget and save
          placeholder.click
          page.find(".ck-balloon-panel .ck-button", visible: :all, text: "Edit").click
          expect(page).to have_css(".spot-modal")
          fill_in "selected-page", with: "parent-page"

          # Save widget
          find(".spot-modal--submit-button").click

          # Placeholder states `parent-page` and no `Include parent`
          expect(placeholder).to have_text("parent-page")
          expect(placeholder).to have_no_text("Include parent")
        end

        # Save wiki page
        click_on "Save"

        expect(page).to have_css(".op-toast.-success")

        within("#content") do
          expect(page).to have_css(".pages-hierarchy")
          expect(page).to have_css(".pages-hierarchy", text: "Child page")
          expect(page).to have_no_css(".pages-hierarchy", text: "Parent page")
          expect(page).to have_css("h1", text: "My page")

          SeleniumHubWaiter.wait
          find(".toolbar .icon-edit").click
        end

        editor.in_editor do |_container, _editable|
          # Find widget, click to show toolbar
          placeholder = find(".op-uc-placeholder", text: "Links to child pages")

          # Edit widget and save
          placeholder.click
          page.find(".ck-balloon-panel .ck-button", visible: :all, text: "Edit").click
          expect(page).to have_css(".spot-modal")
          page.check "include-parent"

          # Save widget
          find(".spot-modal--submit-button").click

          # Placeholder states `parent-page` and `Include parent`
          expect(placeholder).to have_text("parent-page")
          expect(placeholder).to have_text("Include parent")
        end

        # Save wiki page
        click_on "Save"

        expect(page).to have_css(".op-toast.-success")

        within("#content") do
          expect(page).to have_css(".pages-hierarchy")
          expect(page).to have_css(".pages-hierarchy", text: "Child page")
          expect(page).to have_css(".pages-hierarchy", text: "Parent page")
          expect(page).to have_css("h1", text: "My page")

          SeleniumHubWaiter.wait
          find(".toolbar .icon-edit").click
        end
      end
    end
  end
end
