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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

RSpec.describe Projects::HoverCardComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:grandparent) { create(:project, name: "Grandparent") }
  shared_let(:parent) { create(:project, name: "Parent", parent: grandparent) }
  shared_let(:project) { create(:project, name: "Leaf project", parent:) }
  shared_let(:standalone_project) { create(:project, name: "Standalone project") }

  let(:current_user) do
    create(:user,
           member_with_permissions: {
             grandparent => [:view_project],
             parent => [:view_project],
             project => [:view_project],
             standalone_project => [:view_project]
           })
  end
  let(:displayed_project) { project }

  subject { described_class.new(project: displayed_project, user: current_user) }

  before do
    login_as(current_user)
    render_inline(subject)
  end

  it "renders successfully" do
    expect(page).to have_test_selector("project-hover-card-#{project.id}")
    expect(page).to have_css(".op-project-hover-card")
  end

  it "renders the project name as a heading" do
    expect(page).to have_css("h3", text: "Leaf project")
  end

  it "renders the workspace label" do
    expect(page).to have_test_selector("workspace-label-#{project.id}")
  end

  context "when displaying the status badge" do
    let(:displayed_project) { create(:project, status_code: "on_track") }

    it "renders the project status badge" do
      expect(page).to have_test_selector("status-badge-#{displayed_project.id}")
    end
  end

  context "when the project is active" do
    it "does not show the archived label" do
      expect(page).to have_no_text(I18n.t("project.archive.archived"))
    end
  end

  context "when the project is archived" do
    let(:displayed_project) { create(:project, active: false) }

    it "shows the archived label" do
      expect(page).to have_text(I18n.t("project.archive.archived"))
    end
  end

  context "when displaying the hierarchy" do
    context "when the project has no ancestors" do
      let(:displayed_project) { standalone_project }

      it "renders no breadcrumbs" do
        expect(page).to have_no_test_selector("hierarchy-#{project.id}")
      end
    end

    context "when the project has visible ancestors" do
      it "renders the ancestors followed by the project, in hierarchy order" do
        hierarchy = find_test_selector("hierarchy-#{project.id}")

        expect(hierarchy).to have_text("Grandparent")
        expect(hierarchy).to have_text("Parent")
        expect(hierarchy).to have_text("Leaf project")
      end

      it "links each item to the project overview" do
        expect(page).to have_link("Grandparent", href: project_overview_path(grandparent))
        expect(page).to have_link("Parent", href: project_overview_path(parent))
        expect(page).to have_link("Leaf project", href: project_overview_path(project))
      end
    end

    context "when an ancestor is not visible to the user" do
      let(:current_user) do
        create(:user, member_with_permissions: { project => [:view_project], parent => [:view_project] })
      end

      it "omits the hidden ancestor" do
        expect(page).to have_no_text("Grandparent")
        expect(page).to have_text("Parent")
      end
    end

    context "when no ancestor is visible to the user" do
      let(:current_user) do
        create(:user, member_with_permissions: { project => [:view_project] })
      end

      it "renders no breadcrumbs and does not leak ancestor names" do
        expect(page).to have_no_css(".breadcrumb-item")
        expect(page).to have_no_text("Parent")
        expect(page).to have_no_text("Grandparent")
      end
    end

    context "when an ancestor is archived" do
      before do
        parent.update_column(:active, false)
        render_inline(described_class.new(project:, user: current_user))
      end

      it "omits the archived ancestor" do
        expect(page).to have_no_text("Parent")
      end
    end
  end

  describe "#breadcrumb_items" do
    let(:items) { subject.breadcrumb_items }

    context "without ancestors" do
      let(:displayed_project) { standalone_project }

      it "returns nil" do
        expect(items).to be_nil
      end
    end

    context "with visible ancestors" do
      it "returns hashes with href, text and selected" do
        expect(items).to eq(
          [
            { href: project_overview_path(grandparent), text: "Grandparent", selected: false },
            { href: project_overview_path(parent), text: "Parent", selected: false },
            { href: project_overview_path(project), text: "Leaf project", selected: true }
          ]
        )
      end
    end
  end
end
