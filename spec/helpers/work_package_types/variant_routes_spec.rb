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

RSpec.describe WorkPackageTypes::VariantRoutes do
  subject(:routes) { Object.new.extend(described_class) }

  let(:type) { build_stubbed(:type) }
  let(:project) { build_stubbed(:project, identifier: "apollo") }
  let(:base) { build_stubbed(:type_variant, type:, is_default_variant: true, variant_name: nil) }
  let(:named) { build_stubbed(:type_variant, type:, variant_name: "Hardware") }
  let(:owned) { build_stubbed(:project_owned_type_variant, type:, project:, variant_name: "Ours") }

  let(:project_types) { "/projects/apollo/settings/work_packages/types/#{type.id}" }

  describe "a screen administration and a project share" do
    it "addresses the base variant through its type" do
      expect(routes.edit_variant_details_path(nil, base)).to eq("/types/#{type.id}/details/edit")
    end

    it "addresses a named variant under its type" do
      expect(routes.edit_variant_details_path(nil, named))
        .to eq("/types/#{type.id}/variants/#{named.id}/details/edit")
    end

    it "keeps a project's variant in administration when rendered there" do
      expect(routes.edit_variant_details_path(nil, owned))
        .to eq("/types/#{type.id}/variants/#{owned.id}/details/edit")
    end

    it "addresses a variant inside the project the page is rendered in" do
      expect(routes.edit_variant_details_path(project, owned))
        .to eq("#{project_types}/variants/#{owned.id}/details/edit")
    end

    it "fills the segments a screen adds after the variant" do
      expect(routes.variant_configuration_link_dialog_path(project, owned, "defaults"))
        .to eq("#{project_types}/variants/#{owned.id}/link_config/defaults/dialog")
      expect(routes.toggle_variant_pdf_export_template_path(nil, base, "attributes"))
        .to eq("/types/#{type.id}/pdf_export/attributes/toggle")
    end

    it "passes anything else on as query parameters" do
      expect(routes.edit_variant_workflow_path(nil, named, tab: "author"))
        .to eq("/types/#{type.id}/variants/#{named.id}/workflow/edit?tab=author")
    end
  end

  describe "a screen only administration has" do
    it "addresses the base and a named variant alike" do
      expect(routes.edit_variant_projects_path(base)).to eq("/types/#{type.id}/projects/edit")
      expect(routes.edit_variant_projects_path(named))
        .to eq("/types/#{type.id}/variants/#{named.id}/projects/edit")
    end
  end

  describe "#variant_reference_path" do
    it "addresses the reference of the base variant through its type" do
      expect(routes.variant_reference_path(nil, base, Workflow, action: :edit))
        .to eq("/types/#{type.id}/workflow/edit")
    end

    it "addresses the reference of a named variant under its type" do
      expect(routes.variant_reference_path(nil, named, FormConfiguration, action: :change_dialog))
        .to eq("/types/#{type.id}/variants/#{named.id}/form_configuration/change_dialog")
    end

    it "addresses the reference inside the project the page is rendered in" do
      expect(routes.variant_reference_path(project, owned, Workflow, action: :change, back_url: "/back"))
        .to eq("#{project_types}/variants/#{owned.id}/workflow/change?back_url=%2Fback")
    end
  end

  describe "the routes on a type's variants" do
    it "starts the wizard for a new variant in administration or inside a project" do
      expect(routes.new_variant_creation_wizard_path(nil, type))
        .to eq("/types/#{type.id}/variants/creation_wizard/new")
      expect(routes.new_variant_creation_wizard_path(project, type))
        .to eq("#{project_types}/variants/creation_wizard/new")
    end

    it "deletes a variant in administration or inside a project" do
      expect(routes.variant_path(nil, named)).to eq("/types/#{type.id}/variants/#{named.id}")
      expect(routes.variant_path(project, owned)).to eq("#{project_types}/variants/#{owned.id}")
    end
  end
end
