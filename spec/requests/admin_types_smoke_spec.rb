# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Admin types UI smoke", :skip_csrf, type: :rails_request, with_flag: { type_variants: true } do
  shared_let(:admin) { create(:admin) }
  shared_let(:type) { create(:type, name: "SmokeType") }

  before { login_as admin }

  let(:variant) { type.reload.default_variant }

  it "renders the types index, including a type's named variants" do
    type.variants.create!(variant_name: "Hardware")

    get types_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Hardware")
  end

  it "renders the details tab" do
    get edit_type_details_path(type_id: type.id)
    expect(response).to have_http_status(:ok)
  end

  it "renders the form configuration tab for the base variant" do
    get edit_type_form_configuration_path(type_id: type.id, variant_id: variant.id)
    expect(response).to have_http_status(:ok)
  end

  it "renders the defaults tab" do
    get edit_type_defaults_path(type_id: type.id, variant_id: variant.id)
    expect(response).to have_http_status(:ok)
  end

  it "renders the workflow tab" do
    get edit_type_workflow_path(type_id: type.id, variant_id: variant.id)
    expect(response).to have_http_status(:ok)
  end

  it "renders the project attributes tab" do
    get edit_type_project_attributes_path(type_id: type.id, variant_id: variant.id)
    expect(response).to have_http_status(:ok)
  end

  it "renders the pdf export tab" do
    get edit_type_pdf_export_template_index_path(type_id: type.id, variant_id: variant.id)
    expect(response).to have_http_status(:ok)
  end

  it "renders the projects tab" do
    get edit_type_projects_path(type_id: type.id)
    expect(response).to have_http_status(:ok)
  end

  it "creates a named variant" do
    post creation_wizard_types_path(type_id: type.id), params: { type_variant: { variant_name: "Hardware" } }
    expect(response).to have_http_status(:see_other)
    expect(type.reload.variants.named.pluck(:variant_name)).to eq(["Hardware"])
  end
end
