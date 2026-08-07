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

RSpec.describe "Project-scoped variant configuration tabs",
               :skip_csrf,
               type: :rails_request,
               with_flag: { type_variants: true } do
  shared_let(:project) { create(:project) }
  shared_let(:stranger) { create(:project) }
  shared_let(:root) { create(:type, name: "Bug") }
  shared_let(:owned_variant) { create(:type, name: "Ours", parent: root, project:) }
  shared_let(:foreign_variant) { create(:type, name: "Theirs", parent: root, project: stranger) }
  shared_let(:project_admin) do
    create(:user, member_with_permissions: { project => %i[manage_project_variants] })
  end

  before { login_as project_admin }

  # Enumerated rather than spot-checked: a tab added later without the project scoping
  # is the regression this feature most needs to catch.
  def tab_paths(variant)
    {
      "details" => edit_project_settings_work_packages_types_variant_details_path(project, variant),
      "defaults" => edit_project_settings_work_packages_types_variant_defaults_path(project, variant),
      "form configuration" =>
        edit_project_settings_work_packages_types_variant_form_configuration_path(project, variant),
      "workflow" => edit_project_settings_work_packages_types_variant_workflow_path(project, variant),
      "project attributes" =>
        edit_project_settings_work_packages_types_variant_project_attributes_path(project, variant),
      "export configuration" =>
        edit_project_settings_work_packages_types_variant_pdf_export_template_index_path(project, variant)
    }
  end

  it "opens every tab of a variant the project owns" do
    tab_paths(owned_variant).each do |name, path|
      get path

      expect(response).to have_http_status(:ok), "expected the #{name} tab to open"
    end
  end

  # A 200 alone would not prove the tab resolved the right type.
  it "shows the variant being configured" do
    get edit_project_settings_work_packages_types_variant_details_path(project, owned_variant)

    expect(response.body).to include("Ours")
  end

  it "gives 404 on every tab of another project's variant" do
    tab_paths(foreign_variant).each do |name, path|
      get path

      expect(response).to have_http_status(:not_found), "expected the #{name} tab to be absent"
    end
  end

  it "gives 404 on every tab of a global variant" do
    global_variant = create(:type, name: "Global", parent: root)

    tab_paths(global_variant).each do |name, path|
      get path

      expect(response).to have_http_status(:not_found), "expected the #{name} tab to be absent"
    end
  end

  context "without the permission" do
    before { login_as create(:user, member_with_permissions: { project => %i[view_project] }) }

    it "refuses every tab" do
      tab_paths(owned_variant).each do |name, path|
        get path

        expect(response).not_to have_http_status(:ok), "expected the #{name} tab to be refused"
      end
    end
  end

  context "with the variants feature disabled", with_flag: { type_variants: false } do
    it "hides every tab" do
      tab_paths(owned_variant).each do |name, path|
        get path

        expect(response).to have_http_status(:not_found), "expected the #{name} tab to be absent"
      end
    end
  end
end
