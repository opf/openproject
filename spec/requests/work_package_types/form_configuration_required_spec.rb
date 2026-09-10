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
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Work package type required attributes",
               :skip_csrf,
               type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:custom_field) { create(:integer_wp_custom_field) }
  shared_let(:type) { create(:type) }
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }

  shared_let(:global_variant) { type.default_variant }
  shared_let(:owned_variant) { create(:project_owned_type_variant, type:, project:) }
  shared_let(:other_projects_variant) { create(:project_owned_type_variant, type:, project: other_project) }

  shared_let(:project_author) do
    create(:user, member_with_permissions: { project => %i[manage_project_variants] })
  end

  def show_the_field_on(variant)
    variant.attribute_groups = [["Details", [custom_field.attribute_name]]]
    variant.custom_field_ids = [custom_field.id]
    variant.save!
  end

  before do
    [global_variant, owned_variant, other_projects_variant].each { |variant| show_the_field_on(variant) }

    login_as(given_user)
  end

  def toggle(variant, in_project: nil, row_key: custom_field.attribute_name)
    args = { type_id: type.id, variant_id: variant.id, row_key: }
    args[:in_project_id] = in_project if in_project

    put toggle_required_type_form_configuration_row_path(**args),
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
  end

  def required_on(variant)
    variant.reload[:required_attributes]
  end

  describe "administration access" do
    context "when admin" do
      let(:given_user) { admin }

      it "allows to require the field on a global variant", :aggregate_failures do
        toggle(global_variant)

        expect(response).to have_http_status(:ok)
        expect(required_on(global_variant)).to contain_exactly(custom_field.attribute_name)
      end
    end

    context "when project author" do
      let(:given_user) { project_author }

      it "rejects because it's a global variant", :aggregate_failures do
        toggle(global_variant)

        expect(response).to have_http_status(:forbidden)
        expect(required_on(global_variant)).to be_empty
      end
    end

    context "when having no permissions at all" do
      let(:given_user) { create(:user) }

      it "returns forbidden", :aggregate_failures do
        toggle(global_variant)

        expect(response).to have_http_status(:forbidden)
        expect(required_on(global_variant)).to be_empty
      end
    end

    context "as anonymous user" do
      let(:given_user) { User.anonymous }

      it "rejects as an anonymous user", :aggregate_failures do
        toggle(global_variant)

        expect(response).to have_http_status(:unauthorized)
        expect(required_on(global_variant)).to be_empty
      end
    end
  end

  describe "a project's own address" do
    context "when project author" do
      let(:given_user) { project_author }

      it "allows to require the field on a variant the project owns", :aggregate_failures do
        toggle(owned_variant, in_project: project)

        expect(response).to have_http_status(:ok)
        expect(required_on(owned_variant)).to contain_exactly(custom_field.attribute_name)
      end

      it "does not reach the type's global variant from inside the project", :aggregate_failures do
        toggle(global_variant, in_project: project)

        expect(response).to have_http_status(:not_found)
        expect(required_on(global_variant)).to be_empty
      end

      it "does not reach another project's variant", :aggregate_failures do
        toggle(other_projects_variant, in_project: project)

        expect(response).to have_http_status(:not_found)
        expect(required_on(other_projects_variant)).to be_empty
      end
    end

    context "when admin" do
      let(:given_user) { admin }

      it "allows to author a project's variant there too", :aggregate_failures do
        toggle(owned_variant, in_project: project)

        expect(response).to have_http_status(:ok)
        expect(required_on(owned_variant)).to contain_exactly(custom_field.attribute_name)
      end
    end

    context "when a member without the authoring permission" do
      let(:given_user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

      it "returns forbidden", :aggregate_failures do
        toggle(owned_variant, in_project: project)

        expect(response).to have_http_status(:forbidden)
        expect(required_on(owned_variant)).to be_empty
      end
    end
  end

  describe "a row the form does not carry" do
    context "when admin" do
      let(:given_user) { admin }

      it "is unprocessable rather than a silent success", :aggregate_failures do
        toggle(global_variant, row_key: "custom_field_#{custom_field.id + 1000}")

        expect(response).to have_http_status(:unprocessable_entity)
        expect(required_on(global_variant)).to be_empty
      end
    end
  end
end
