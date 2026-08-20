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

RSpec.describe "Work package type projects tab", :js do
  shared_let(:admin) { create(:admin) }
  shared_let(:parent) { create(:project, name: "Parent") }
  shared_let(:child) { create(:project, name: "Child", parent:) }
  shared_let(:sibling) { create(:project, name: "Sibling", parent:) }

  let(:type) { create(:type, name: "Deliverable") }
  let(:tree) { Components::TreeView.new }

  before do
    login_as admin
    visit edit_type_projects_path(type)
  end

  def save_projects
    click_on "Save"
    expect_flash(message: I18n.t(:notice_successful_update))
  end

  it "activates a parent project even when only some of its children are active" do
    tree.click_node "Child"
    save_projects

    expect(type.reload.projects).to contain_exactly(child)

    tree.click_node "Parent"
    save_projects

    expect(type.reload.projects).to contain_exactly(parent, child)
    expect(page).to have_css('.TreeViewItemContent[aria-checked="true"]', text: "Parent")
  end

  it "deactivates a project again" do
    tree.click_node "Child"
    tree.click_node "Sibling"
    save_projects

    tree.click_node "Child"
    save_projects

    expect(type.reload.projects).to contain_exactly(sibling)
  end

  describe "the 'enable for all projects' switch" do
    it "activates and deactivates the type in every project" do
      page.find(".ToggleSwitch-track").click

      expect(page).to have_css('.TreeViewItemContent[aria-checked="true"]', count: 3)
      expect(type.reload.projects).to contain_exactly(parent, child, sibling)

      page.find(".ToggleSwitch-track").click

      expect(page).to have_no_css('.TreeViewItemContent[aria-checked="true"]')
      expect(type.reload.projects).to be_empty
    end

    context "when the type is still in use by work packages" do
      let(:type) { create(:type, name: "Deliverable", projects: [parent, child, sibling]) }
      let!(:work_package) { create(:work_package, project: child, type:) }

      it "keeps the tree available so single projects can be deactivated instead" do
        page.find(".ToggleSwitch-track").click

        expect_and_dismiss_flash(
          type: :error,
          message: "Unable to deactivate type #{type.name} because it's still in use by work packages"
        )
        expect(page).to have_css(".ToggleSwitch--checked")
        expect(type.reload.projects).to contain_exactly(parent, child, sibling)

        tree.click_node "Sibling"
        save_projects

        expect(type.reload.projects).to contain_exactly(parent, child)
      end
    end
  end
end
