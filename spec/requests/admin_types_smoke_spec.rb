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

RSpec.describe "Admin types UI smoke", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:type) { create(:type, name: "SmokeType") }

  before { login_as admin }

  let(:variant) { type.reload.default_variant }

  it "renders the types index, including a type's named variants" do
    type.variants.create!(variant_name: "Hardware", workflow: type.default_variant.workflow,
                          form_configuration: type.default_variant.form_configuration)

    get types_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Hardware")
  end

  it "renders the details tab" do
    get edit_type_details_path(type_id: type.id)
    expect(response).to have_http_status(:ok)
  end

  it "renders the form configuration tab for the base variant" do
    get edit_type_form_configuration_path(type_id: type.id)
    expect(response).to have_http_status(:ok)
  end

  it "renders the defaults tab" do
    get edit_type_defaults_path(type_id: type.id)
    expect(response).to have_http_status(:ok)
  end

  it "renders the workflow tab" do
    get edit_type_workflow_path(type_id: type.id)
    expect(response).to have_http_status(:ok)
  end

  it "renders the project attributes tab" do
    get edit_type_project_attributes_path(type_id: type.id)
    expect(response).to have_http_status(:ok)
  end

  it "renders the pdf export tab" do
    get edit_type_pdf_export_template_index_path(type_id: type.id)
    expect(response).to have_http_status(:ok)
  end

  it "renders the projects tab" do
    get edit_type_projects_path(type_id: type.id)
    expect(response).to have_http_status(:ok)
  end

  it "renders the projects tab with a project applying the variant" do
    project = create(:project, name: "Bookshop", types: [variant])

    get edit_type_projects_path(type_id: type.id)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(project.name)
  end

  it "asks for confirmation before removing a project" do
    project = create(:project, name: "Bookshop", types: [variant])

    get edit_type_projects_path(type_id: type.id)

    confirmation = I18n.t("types.edit.projects.actions.confirm_remove", project: project.name, type: type.name)

    expect(response.body).to include(CGI.escapeHTML(confirmation))
  end

  it "renders the add projects dialog" do
    get new_link_type_projects_path(type_id: type.id), as: :turbo_stream

    expect(response).to have_http_status(:ok)
  end

  it "renders the project tree the add dialog picks from" do
    create(:project, name: "Bookshop")

    get tree_type_projects_path(type_id: type.id, name: "project_ids")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Bookshop")
  end

  it "renders the switch dialog for a listed project" do
    project = create(:project, types: [variant])

    get new_switch_type_projects_path(type_id: type.id, project_id: project.id),
        as: :turbo_stream

    expect(response).to have_http_status(:ok)
  end

  # The variants tab lists every project's, and an administrator configures them in administration.
  # A variant a project owns is only ever used there, so which projects use it is not a question.
  describe "a variant a project owns, reached from the variants tab" do
    shared_let(:owning_project) { create(:project) }
    shared_let(:owned) do
      create(:project_owned_type_variant, type:, project: owning_project, variant_name: "Internal")
    end

    it "opens at administration's address" do
      get edit_type_variant_details_path(type_id: type.id, variant_id: owned.id)

      expect(response).to have_http_status(:ok)
    end

    it "offers no projects tab there" do
      get edit_type_variant_details_path(type_id: type.id, variant_id: owned.id)

      expect(response.body).not_to include(edit_type_variant_projects_path(type_id: type.id, variant_id: owned.id))
    end
  end

  it "creates a named variant" do
    post creation_wizard_type_variants_path(type_id: type.id), params: { type_variant: { variant_name: "Hardware" } }
    expect(response).to have_http_status(:see_other)
    expect(type.reload.variants.non_default_variants.pluck(:variant_name)).to eq(["Hardware"])
  end
end
