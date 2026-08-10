# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe WorkPackageTypes::ProjectAttributesTabController do
  let(:type) { create(:type) }
  let(:variant) { type.default_variant }
  let(:project_custom_field_section) { create(:project_custom_field_section) }
  let!(:project_custom_field) { create(:project_custom_field, project_custom_field_section:) }

  before do
    login_as user
  end

  context "without admin access" do
    let(:user) { create(:user) }

    describe "GET edit" do
      before do
        get :edit, params: { type_id: type.id }
      end

      it { expect(response).to have_http_status(:forbidden) }
    end

    describe "POST toggle" do
      before do
        post :toggle,
             params: {
               type_id: type.id,
               value: "1",
               project_custom_field_type_mapping: {
                 variant_id: variant.id,
                 custom_field_id: project_custom_field.id
               }
             }
      end

      it "does not enable the project attribute" do
        expect(response).to have_http_status(:forbidden)
        expect(variant.reload.project_custom_fields).to be_empty
      end
    end
  end

  context "with admin access" do
    let(:user) { create(:admin) }

    describe "GET edit" do
      before do
        get :edit, params: { type_id: type.id }
      end

      it { expect(response).to have_http_status(:ok) }
      it { expect(response).to render_template "edit" }
    end

    describe "POST toggle" do
      let(:params) do
        {
          type_id: type.id,
          value: "1",
          project_custom_field_type_mapping: {
            variant_id: variant.id,
            custom_field_id: project_custom_field.id
          }
        }
      end

      it "enables the project attribute for the type" do
        post :toggle, params: params

        expect(response).to have_http_status(:ok)
        expect(variant.reload.project_custom_fields).to contain_exactly(project_custom_field)
      end
    end

    describe "PUT enable_all_of_section" do
      let(:params) do
        {
          type_id: type.id,
          project_custom_field_type_mapping: {
            variant_id: variant.id,
            custom_field_section_id: project_custom_field_section.id
          }
        }
      end

      it "enables all project attributes of the section" do
        put :enable_all_of_section, params: params, format: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(variant.reload.project_custom_fields).to contain_exactly(project_custom_field)
      end
    end

    describe "PUT disable_all_of_section" do
      let(:params) do
        {
          type_id: type.id,
          project_custom_field_type_mapping: {
            variant_id: variant.id,
            custom_field_section_id: project_custom_field_section.id
          }
        }
      end

      before do
        variant.project_custom_fields << project_custom_field
      end

      it "disables all project attributes of the section" do
        put :disable_all_of_section, params: params, format: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(variant.reload.project_custom_fields).to be_empty
      end
    end

    describe "a failed bulk update" do
      let(:params) do
        {
          type_id: type.id,
          project_custom_field_type_mapping: {
            variant_id: variant.id,
            custom_field_section_id: project_custom_field_section.id
          }
        }
      end

      let(:service) { instance_double(ProjectCustomFieldTypeMappings::BulkUpdateService) }

      before do
        allow(ProjectCustomFieldTypeMappings::BulkUpdateService).to receive(:new).and_return(service)
        allow(service).to receive(:call).and_return(
          ServiceResult.failure(message: "Project attributes could not be updated.")
        )
      end

      it "shows an error message" do
        put :enable_all_of_section, params: params, format: :turbo_stream

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Project attributes could not be updated.")
      end
    end

    context "when the type is linked", with_flag: { type_variants: true } do
      let(:aspect) { TypeVariant::PROJECT_ATTRIBUTES }
      let(:source) { create(:type).default_variant }
      let(:link) { variant }
      let(:params) do
        {
          type_id: type.id,
          project_custom_field_type_mapping: {
            variant_id: variant.id,
            custom_field_section_id: project_custom_field_section.id
          }
        }
      end

      before do
        source.project_custom_fields << project_custom_field
        link_configuration(variant, source:, aspect:)
      end

      describe "PUT disable_all_of_section" do
        it "excludes the section's inherited attributes on the link" do
          expect(excluded_configuration_elements(link, aspect:)).to be_empty

          put :disable_all_of_section, params: params, format: :turbo_stream

          expect(response).to have_http_status(:ok)
          expect(excluded_configuration_elements(link, aspect:)).to contain_exactly(project_custom_field.attribute_name)
          expect(variant.own_project_custom_field_type_mappings.map(&:custom_field_id)).to be_empty
        end
      end

      describe "PUT enable_all_of_section" do
        before { exclude_configuration_elements(link, aspect:, elements: [project_custom_field.attribute_name]) }

        it "re-inherits the section's attributes" do
          put :enable_all_of_section, params: params, format: :turbo_stream

          expect(response).to have_http_status(:ok)
          expect(excluded_configuration_elements(link, aspect:)).to be_empty
          expect(variant.project_custom_field_type_mappings.map(&:custom_field_id))
            .to contain_exactly(project_custom_field.id)
        end
      end
    end
  end
end
