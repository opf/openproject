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

require "spec_helper"

RSpec.describe "Purpose descriptions on the type and variant aspects", type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:variant) { create(:type_variant, type:, variant_name: "Hardware") }

  before { login_as admin }

  def description(key)
    I18n.t("types.aspect_descriptions.#{key}")
  end

  def rendered_description
    response.parsed_body.at_css("[data-test-selector='aspect-description']")&.text&.strip
  end

  shared_examples "an aspect description" do |key|
    it "renders the #{key} description" do
      get path

      expect(response).to have_http_status(:ok)
      expect(rendered_description).to eq(description(key))
    end
  end

  describe "the type edit tabs" do
    {
      edit_type_details_path: "details.type",
      edit_type_defaults_path: "defaults.type",
      type_variants_path: "variants",
      edit_type_form_configuration_path: "form_configuration.existing.type",
      edit_type_workflow_path: "workflows",
      edit_type_project_attributes_path: "project_attributes",
      edit_type_projects_path: "projects.type",
      edit_type_pdf_export_template_index_path: "pdf"
    }.each do |route, key|
      context "on #{route}" do
        let(:path) { public_send(route, type) }

        it_behaves_like "an aspect description", key
      end
    end

    it "captions the description template for the type" do
      get edit_type_defaults_path(type)

      expect(response.body).to include(I18n.t("types.edit.defaults.description.caption.type"))
    end
  end

  describe "the variant edit tabs" do
    {
      edit_type_variant_details_path: "details.variant",
      edit_type_variant_defaults_path: "defaults.variant",
      edit_type_variant_form_configuration_path: "form_configuration.existing.variant",
      edit_type_variant_projects_path: "projects.variant"
    }.each do |route, key|
      context "on #{route}" do
        let(:path) { public_send(route, type, variant) }

        it_behaves_like "an aspect description", key
      end
    end

    it "captions the description template for the variant" do
      get edit_type_variant_defaults_path(type, variant)

      expect(response.body).to include(I18n.t("types.edit.defaults.description.caption.variant"))
    end
  end

  describe "the creation wizard" do
    context "on the details step of a new type" do
      let(:path) { new_creation_wizard_types_path(step: :details) }

      it_behaves_like "an aspect description", "details.type"
    end

    context "on the form step with an existing form" do
      let(:path) { type_creation_wizard_path(type, step: :form_configuration) }

      it_behaves_like "an aspect description", "form_configuration.existing.type"
    end

    context "on the form step with the form it started" do
      let(:path) do
        type_creation_wizard_path(type, step: :form_configuration,
                                        started_form_configuration_id: type.default_variant.form_configuration_id)
      end

      it_behaves_like "an aspect description", "form_configuration.new.type"
    end

    context "on the form step of a variant with the form it started" do
      let(:path) do
        type_variant_creation_wizard_path(type, variant, step: :form_configuration,
                                                         started_form_configuration_id: variant.form_configuration_id)
      end

      it_behaves_like "an aspect description", "form_configuration.new.variant"
    end

    context "on the projects step of a type" do
      let(:path) { type_creation_wizard_path(type, step: :projects) }

      it_behaves_like "an aspect description", "projects.type"
    end

    context "on the projects step of a variant" do
      let(:path) { type_variant_creation_wizard_path(type, variant, step: :projects) }

      it_behaves_like "an aspect description", "projects.variant"
    end
  end
end
