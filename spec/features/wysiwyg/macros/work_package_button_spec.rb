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

RSpec.describe "Wysiwyg work package button spec", :js do
  shared_let(:admin) { create(:admin) }
  let(:user) { admin }

  let!(:type) { create(:type, name: "MyTaskName") }
  let(:project) do
    create(:valid_project,
           identifier: "my-project",
           enabled_module_names: %w[wiki work_package_tracking],
           name: "My project name",
           types: [type])
  end

  let(:editor) { Components::WysiwygEditor.new }

  before do
    login_as(user)
  end

  describe "in wikis" do
    describe "creating a wiki page" do
      before do
        visit project_wiki_path(project, :wiki)
      end

      it "can add and edit an embedded table widget" do
        editor.in_editor do |_container, editable|
          editor.insert_macro "Insert create work package button"

          expect(page).to have_css(".spot-modal")
          select "MyTaskName", from: "selected-type"

          # Cancel editing
          find(".spot-modal--cancel-button").click
          expect(editable).to have_no_css(".macro.-create_work_package_link")

          editor.insert_macro  "Insert create work package button"
          select "MyTaskName", from: "selected-type"
          check "button_style"

          # Save widget
          find(".spot-modal--submit-button").click

          # Find widget, click to show toolbar
          modal = find(".button.op-uc-placeholder", text: "Create work package")

          # Edit widget again
          modal.click
          page.find(".ck-balloon-panel .ck-button", visible: :all, text: "Edit").click
          expect(page).to have_checked_field("wp_button_macro_style")
          expect(page).to have_select("selected-type", selected: "MyTaskName")
          find(".spot-modal--cancel-button").click
        end

        # Save wiki page
        click_on "Save"

        expect(page).to have_css(".op-toast.-success")

        within("#content") do
          expect(page).to have_css("a[href=\"/projects/my-project/work_packages/new?type=#{type.id}\"]")
        end
      end
    end
  end
end
