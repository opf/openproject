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

RSpec.describe WorkPackageTypes::VariantPathsHelper do
  shared_let(:project) { create(:project) }
  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:variant) { create(:type_variant, type:, variant_name: "Mobile") }

  # Every tab route the shared components name, enumerated rather than sampled: the point of the
  # rewrite is that it holds for all of them, and a route added to the shared concern later
  # without a project mount is exactly what this should catch.
  let(:buildable_routes) do
    %i[
      edit_type_details_path
      type_details_path
      edit_type_defaults_path
      type_defaults_path
      edit_type_form_configuration_path
      type_form_configuration_path
      edit_type_workflow_path
      edit_type_project_attributes_path
      edit_type_pdf_export_template_index_path
      type_creation_wizard_path
      type_workflow_matrix_path
    ]
  end

  # Also named by the shared components, but needing more than the variant to build a path.
  let(:other_shared_routes) do
    %i[
      type_configuration_link_dialog_path
      type_configuration_independence_dialog_path
      type_configuration_copy_dialog_path
      type_workflow_copy_from_variant_path
      type_workflow_copy_from_role_path
      toggle_type_pdf_export_template_path
      drop_type_pdf_export_template_path
      enable_all_type_pdf_export_template_index_path
      update_artefact_export_type_pdf_export_template_index_path
      type_excluded_element_toggle_path
      type_form_configuration_group_path
      type_form_configuration_groups_path
    ]
  end

  let(:shared_routes) { buildable_routes + other_shared_routes }

  # Administration alone. Which projects use a type is an instance-wide decision, and a variant a
  # project owns is only ever used in that project — the rest of the reuse screens moved into
  # projects once the sources they offer were scoped to what the variant may use.
  let(:administration_only_routes) do
    %i[
      type_projects_path
      enable_all_type_projects_path
    ]
  end

  context "when configuring from administration" do
    before { assign(:project, nil) }

    it "names the administration route unchanged" do
      expect(helper.scoped_variant_path(:edit_type_details_path, **variant.path_args))
        .to eq(edit_type_details_path(**variant.path_args))
    end

    it "knows every shared route" do
      shared_routes.each do |route|
        expect(helper.scoped_variant_route?(route)).to be(true), "expected #{route} in administration"
      end
    end

    it "knows the routes only administration has" do
      administration_only_routes.each do |route|
        expect(helper.scoped_variant_route?(route)).to be(true), "expected #{route} in administration"
      end
    end
  end

  context "when configuring from a project's settings" do
    before { assign(:project, project) }

    it "names the project-scoped route and supplies the project" do
      expect(helper.scoped_variant_path(:edit_type_details_path, **variant.path_args))
        .to eq(edit_project_settings_work_packages_type_details_path(project, type, variant_id: variant.id))
    end

    it "knows every shared route" do
      shared_routes.each do |route|
        expect(helper.scoped_variant_route?(route)).to be(true), "expected #{route} under a project"
      end
    end

    it "keeps the project in every path it builds" do
      buildable_routes.each do |route|
        expect(helper.scoped_variant_path(route, **variant.path_args))
          .to include("/projects/#{project.identifier}/"), "expected #{route} to stay in the project"
      end
    end

    it "reports the administration-only routes as absent" do
      administration_only_routes.each do |route|
        expect(helper.scoped_variant_route?(route)).to be(false), "expected #{route} to be absent here"
      end
    end

    # Silently falling back to the administration path would hand a project administrator a URL
    # they cannot use and — as the wizard did — write to the global configuration instead.
    it "refuses to build an administration-only path" do
      expect { helper.scoped_variant_path(:type_projects_path, **variant.path_args) }
        .to raise_error(ArgumentError, /no counterpart/)
    end

    it "offers nil instead of raising where a control is simply not on offer" do
      expect(helper.scoped_variant_path_if_available(:type_projects_path, **variant.path_args)).to be_nil
    end
  end
end
