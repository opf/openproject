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

RSpec.describe "Creating a project-owned variant",
               :skip_csrf,
               type: :rails_request,
               with_flag: { type_variants: true } do
  shared_let(:project) { create(:project) }
  shared_let(:root) { create(:type, name: "Bug") }
  shared_let(:project_admin) do
    create(:user, member_with_permissions: { project => %i[manage_project_variants] })
  end

  before { login_as project_admin }

  def create_variant(attributes)
    post creation_wizard_project_settings_work_packages_types_variants_path(project), params: { type: attributes }
  end

  it "opens the first step" do
    get new_creation_wizard_project_settings_work_packages_types_variants_path(project, parent_id: root.id)

    expect(response).to have_http_status(:ok)
  end

  describe "the steps an owned variant has" do
    shared_let(:owned_variant) { create(:type, name: "Ours", parent: root, project:) }

    # The acceptance criterion is that an owned variant is only ever activated in the project
    # owning it. The step that picks projects offered a checkbox per project in the instance,
    # so hiding it from the sidebar is not enough — the URL must not serve it either.
    it "gives 404 for the projects step" do
      get project_settings_work_packages_types_variant_creation_wizard_path(
        project, owned_variant, step: "projects"
      )

      expect(response).to have_http_status(:not_found)
    end

    it "still serves the steps it does have" do
      get project_settings_work_packages_types_variant_creation_wizard_path(
        project, owned_variant, step: "defaults"
      )

      expect(response).to have_http_status(:ok)
    end

    # Only owned variants lose the step; a global variant is still activated per project.
    it "leaves the projects step alone for a global variant" do
      login_as create(:admin)
      global_variant = create(:type, name: "Global", parent: root)

      get type_creation_wizard_path(global_variant, step: "projects")

      expect(response).to have_http_status(:ok)
    end

    # Reuse mode is configured from administration, whose dialogs this user cannot open.
    it "offers no reuse-mode switch it cannot honour" do
      get project_settings_work_packages_types_variant_creation_wizard_path(
        project, owned_variant, step: "defaults"
      )

      expect(response.body).not_to include("Switch to independent mode")
      expect(response.body).not_to include("Change source type")
    end
  end

  describe "the links and forms the wizard renders" do
    before { get new_creation_wizard_project_settings_work_packages_types_variants_path(project, parent_id: root.id) }

    # The page rendering is not enough: the step form posting to /types is what silently
    # refused the project administrator on "Continue".
    it "submits into the project rather than into administration" do
      expect(response.body).to include(
        creation_wizard_project_settings_work_packages_types_variants_path(project)
      )
      expect(response.body).not_to include('action="/types')
    end

    it "links nowhere into global type administration" do
      expect(response.body).not_to include('href="/types')
    end
  end

  it "stamps the project as the owner of what it creates" do
    create_variant(name: "Internal bug", parent_id: root.id)

    expect(project.owned_types.pluck(:name)).to include("Internal bug")
  end

  # A project administrator has no route to a global type, and the wizard is the one place
  # they could otherwise make one.
  it "refuses to create a root" do
    create_variant(name: "Rogue root", parent_id: nil)

    expect(Type.global.where(name: "Rogue root")).to be_empty
  end

  # The owner comes from the URL, never from the request body.
  it "ignores a project named in the request" do
    create_variant(name: "Smuggled", parent_id: root.id, project_id: create(:project).id)

    expect(project.owned_types.pluck(:name)).to include("Smuggled")
  end

  it "moves on to the next step rather than to global administration" do
    create_variant(name: "Internal bug", parent_id: root.id)

    expect(response).to redirect_to(
      %r{/projects/#{project.identifier}/settings/work_packages/types/variants/\d+/creation_wizard}
    )
  end

  context "without the permission" do
    before { login_as create(:user, member_with_permissions: { project => %i[view_project] }) }

    it "creates nothing" do
      create_variant(name: "Nope", parent_id: root.id)

      expect(Type.where(name: "Nope")).to be_empty
    end
  end

  context "with the variants feature disabled", with_flag: { type_variants: false } do
    it "is absent" do
      get new_creation_wizard_project_settings_work_packages_types_variants_path(project, parent_id: root.id)

      expect(response).to have_http_status(:not_found)
    end
  end
end
