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
            type_id: type.id,
            custom_field_id: project_custom_field.id
          }
        }
      end

      it "enables the project attribute for the type" do
        post :toggle, params: params

        expect(response).to have_http_status(:ok)
        expect(type.reload.project_custom_fields).to contain_exactly(project_custom_field)
      end
    end

    describe "PUT enable_all_of_section" do
      let(:params) do
        {
          type_id: type.id,
          project_custom_field_type_mapping: {
            type_id: type.id,
            custom_field_section_id: project_custom_field_section.id
          }
        }
      end

      it "enables all project attributes of the section" do
        put :enable_all_of_section, params: params, format: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(type.reload.project_custom_fields).to contain_exactly(project_custom_field)
      end
    end
  end
end
