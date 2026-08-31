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

# A member who may author the project's own variants can reach them, apply one and take it back
# off again, without also holding the permission to choose which types the project uses.
RSpec.describe "Switching to a variant a project owns",
               :skip_csrf,
               type: :rails_request,
               with_flag: { type_variants: true } do
  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:base) { type.default_variant }
  shared_let(:global) { create(:type_variant, type:, variant_name: "Mobile") }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:ours) { create(:project_owned_type_variant, type:, project:, variant_name: "Internal") }

  shared_let(:variant_author) do
    create(:user, member_with_permissions: { project => %i[view_project manage_project_variants] })
  end

  before { login_as variant_author }

  def applied_variant = project.reload.project_types.find_by(type:).variant

  def switch_to(target)
    post project_settings_work_packages_type_switch_path(project, type),
         params: { target_id: target.id },
         as: :turbo_stream
  end

  def use_variant(variant)
    project.project_types.find_by(type:).update!(variant:)
  end

  describe "the project's types page" do
    before { get project_settings_work_packages_types_path(project) }

    it "opens" do
      expect(response).to have_http_status(:ok)
    end

    it "lists the variant the project owns" do
      expect(response.body).to include("Internal")
    end

    # Which types the project uses is not theirs to change, so the page offers none of it.
    it "offers no way to add or remove a type" do
      expect(response.body).not_to include("project-types-add-button")
      expect(response.body).not_to include("Remove from project")
    end

    it "offers the variant it owns for use" do
      expect(response.body).to include("Use in this project")
    end
  end

  it "sends them to the types page from the work packages settings" do
    get project_settings_work_packages_path(project)

    expect(response).to redirect_to(project_settings_work_packages_types_path(project))
  end

  # Both permissions reach the same page, so both need the same way in: the sidebar's Project
  # settings entry deep-links to the first settings section the member may open, and this is the
  # one that leads to the types.
  context "when the member may only choose which types the project uses" do
    before { login_as create(:user, member_with_permissions: { project => %i[view_project manage_types] }) }

    it "sends them to the types page from the work packages settings" do
      get project_settings_work_packages_path(project)

      expect(response).to redirect_to(project_settings_work_packages_types_path(project))
    end

    it "refuses the switch dialog" do
      get new_project_settings_work_packages_type_switch_path(project, type), as: :turbo_stream

      expect(response).to have_http_status(:forbidden)
    end

    it "refuses the switch" do
      switch_to(ours)

      expect(applied_variant).to eq(base)
    end
  end

  it "opens the switch dialog" do
    get new_project_settings_work_packages_type_switch_path(project, type, target_id: ours.id),
        as: :turbo_stream

    expect(response).to have_http_status(:ok)
  end

  it "switches the project to the variant it owns" do
    switch_to(ours)

    expect(applied_variant).to eq(ours)
  end

  it "switches the project back off it" do
    use_variant(ours)

    switch_to(base)

    expect(applied_variant).to eq(base)
  end

  # Which variant the project uses is the project's own choice, whether or not the project
  # authored the variant.
  it "switches the project to a variant every project shares" do
    switch_to(global)

    expect(applied_variant).to eq(global)
  end

  it "refuses a switch to a variant another project owns" do
    theirs = create(:project_owned_type_variant, type:, project: create(:project), variant_name: "Demo only")

    switch_to(theirs)

    expect(applied_variant).to eq(base)
  end

  context "when the member may not author the project's variants" do
    before { login_as create(:user, member_with_permissions: { project => %i[view_project] }) }

    it "refuses the types page" do
      get project_settings_work_packages_types_path(project)

      expect(response).not_to have_http_status(:ok)
    end

    it "refuses the switch" do
      switch_to(ours)

      expect(applied_variant).to eq(base)
    end
  end
end
