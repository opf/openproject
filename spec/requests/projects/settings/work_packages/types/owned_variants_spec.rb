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

RSpec.describe "Configuring the variants a project owns",
               :skip_csrf,
               type: :rails_request,
               with_flag: { type_variants: true } do
  shared_let(:project) { create(:project) }
  shared_let(:stranger) { create(:project) }
  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:ours) { create(:project_owned_type_variant, type:, project:, variant_name: "Ours") }
  shared_let(:theirs) { create(:project_owned_type_variant, type:, project: stranger, variant_name: "Theirs") }
  shared_let(:global) { create(:type_variant, type:, variant_name: "Global") }
  shared_let(:project_admin) do
    create(:user, member_with_permissions: { project => %i[manage_project_variants] })
  end

  before { login_as project_admin }

  # Enumerated rather than spot-checked: a tab added to the shared routing concern later
  # without the project scoping is the regression this most needs to catch.
  def tab_paths(variant)
    {
      "details" => edit_type_details_path(in_project_id: project, type_id: type.id, variant_id: variant.id),
      "defaults" => edit_type_defaults_path(in_project_id: project, type_id: type.id, variant_id: variant.id),
      "form configuration" =>
        edit_type_form_configuration_path(in_project_id: project, type_id: type.id, variant_id: variant.id),
      "workflow" => edit_type_workflow_path(in_project_id: project, type_id: type.id, variant_id: variant.id),
      "project attributes" =>
        edit_type_project_attributes_path(in_project_id: project, type_id: type.id, variant_id: variant.id),
      "export configuration" =>
        edit_type_pdf_export_template_index_path(in_project_id: project, type_id: type.id, variant_id: variant.id)
    }
  end

  describe "a variant the project owns" do
    it "opens every tab" do
      tab_paths(ours).each do |name, path|
        get path

        expect(response).to have_http_status(:ok), "expected the #{name} tab to open"
      end
    end

    it "shows the variant being configured" do
      get edit_type_details_path(in_project_id: project, type_id: type.id, variant_id: ours.id)

      expect(response.body).to include("Ours")
    end
  end

  # Opening a tab is not configuring it. Every one of these writes is authorized on the record
  # rather than by the route, so a contract that still asks for an instance administrator refuses
  # the very thing this permission is for — and answers 200 or 422 rather than 403, which no
  # status-code assertion on a GET would notice.
  describe "saving what it owns" do
    it "renames it from the details tab" do
      patch type_details_path(in_project_id: project, type_id: type.id, variant_id: ours.id),
            params: { type_variant: { variant_name: "Renamed" } }

      expect(ours.reload.variant_name).to eq("Renamed")
    end

    it "sets a default description from the defaults tab" do
      patch type_defaults_path(in_project_id: project, type_id: type.id, variant_id: ours.id),
            params: { work_package_types_forms_defaults_form_model: {
              subject_configuration: "free", pattern: "", default_work_package_description: "Start here"
            } }

      expect(ours.reload.default_work_package_description).to eq("Start here")
    end

    # Renaming a group is an Enterprise action, so the guard has to be satisfied for the
    # authorization underneath it to be the thing under test.
    it "rewrites the form configuration", with_ee: %i[edit_attribute_groups] do
      groups = [{ type: "attribute",
                  name: "People",
                  attributes: [{ key: "assignee", is_cf: nil, is_required: nil, translation: "Assignee" }],
                  query: nil }]

      patch type_form_configuration_path(in_project_id: project, type_id: type.id, variant_id: ours.id),
            params: { type: { attribute_groups: groups.to_json } }

      expect(ours.reload.attribute_groups.map(&:key)).to eq(%w[People])
    end
  end

  # Every action the concern routes has to be in the permission map, or #authorize raises on a
  # permission it cannot find rather than answering. The export tab's per-template settings are
  # part of an aspect the project configures, so they belong to it.
  describe "the export tab's per-template settings" do
    it "opens for a template of the variant it owns" do
      get edit_settings_type_pdf_export_template_path(in_project_id: project, type_id: type.id,
                                                      variant_id: ours.id, id: "attributes"),
          as: :turbo_stream

      expect(response).to have_http_status(:ok)
    end

    it "saves them" do
      patch update_settings_type_pdf_export_template_path(in_project_id: project, type_id: type.id,
                                                          variant_id: ours.id, id: "attributes"),
            params: { settings: {} }, as: :turbo_stream

      expect(response).not_to have_http_status(:forbidden)
    end
  end

  describe "a variant another project owns" do
    it "gives 404 on every tab" do
      tab_paths(theirs).each do |name, path|
        get path

        expect(response).to have_http_status(:not_found), "expected the #{name} tab to be absent"
      end
    end

    it "cannot be deleted from here" do
      delete type_variant_path(in_project_id: project, type_id: type.id, id: theirs.id)

      expect(response).to have_http_status(:not_found)
      expect(TypeVariant).to exist(theirs.id)
    end
  end

  # A global variant belongs to every project, so a single project may not rewrite it.
  describe "a global variant" do
    it "gives 404 on every tab" do
      tab_paths(global).each do |name, path|
        get path

        expect(response).to have_http_status(:not_found), "expected the #{name} tab to be absent"
      end
    end
  end

  # One route serves both addresses, so the variant segment is optional in each and a project path
  # without one does generate. What keeps the type's own configuration out of a project's reach is
  # the lookup: it only ever considers the variants that project owns.
  describe "the type's own configuration" do
    it "is absent from a project, which addresses no variant" do
      get edit_type_details_path(in_project_id: project, type_id: type.id)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "without the permission" do
    before { login_as create(:user, member_with_permissions: { project => %i[view_project] }) }

    it "refuses every tab" do
      tab_paths(ours).each do |name, path|
        get path

        expect(response).not_to have_http_status(:ok), "expected the #{name} tab to be refused"
      end
    end
  end

  describe "with the variants feature disabled", with_flag: { type_variants: false } do
    it "hides every tab" do
      tab_paths(ours).each do |name, path|
        get path

        expect(response).to have_http_status(:not_found), "expected the #{name} tab to be absent"
      end
    end
  end

  describe "creating one" do
    it "opens the wizard" do
      get new_creation_wizard_types_path(in_project_id: project, type_id: type.id)

      expect(response).to have_http_status(:ok)
    end

    it "creates a variant owned by this project" do
      expect do
        post creation_wizard_types_path(in_project_id: project, type_id: type.id),
             params: { type_variant: { variant_name: "Internal" } }
      end.to change { project.owned_type_variants.count }.by(1)

      expect(project.owned_type_variants.last.variant_name).to eq("Internal")
    end

    # The owner comes from the route. A body naming another project must not be honoured.
    it "ignores an owner named in the request body" do
      post creation_wizard_types_path(in_project_id: project, type_id: type.id),
           params: { type_variant: { variant_name: "Injected", project_id: stranger.id } }

      expect(TypeVariant.find_by(variant_name: "Injected").project).to eq(project)
    end
  end

  describe "deleting one it owns" do
    it "removes it" do
      variant = create(:project_owned_type_variant, type:, project:, variant_name: "Doomed")

      delete type_variant_path(in_project_id: project, type_id: type.id, id: variant.id)

      expect(TypeVariant).not_to exist(variant.id)
    end
  end

  # Choosing what a configuration is borrowed from, and copying a workflow, are offered inside a
  # project now that both ends are scoped to what the variant may use.
  describe "reusing another configuration" do
    let(:aspect) { TypeVariant::DEFAULTS }

    it "opens the source picker" do
      get type_configuration_link_dialog_path(in_project_id: project, type_id: type.id, variant_id: ours.id, aspect:),
          as: :turbo_stream

      expect(response).to have_http_status(:ok)
    end

    it "links to a global source" do
      post type_configuration_link_switch_path(in_project_id: project, type_id: type.id, variant_id: ours.id, aspect:),
           params: { source_id: global.id }, as: :turbo_stream

      expect(ours.reload.source_for(aspect)).to eq(global)
    end

    it "links to a sibling the same project owns" do
      sibling = create(:project_owned_type_variant, type:, project:, variant_name: "Sibling")

      post type_configuration_link_switch_path(in_project_id: project, type_id: type.id, variant_id: ours.id, aspect:),
           params: { source_id: sibling.id }, as: :turbo_stream

      expect(ours.reload.source_for(aspect)).to eq(sibling)
    end

    # The rule the whole feature turns on, at the endpoint rather than in the picker.
    it "refuses a source another project owns" do
      post type_configuration_link_switch_path(in_project_id: project, type_id: type.id, variant_id: ours.id, aspect:),
           params: { source_id: theirs.id }, as: :turbo_stream

      expect(ours.reload.source_for(aspect)).to be_nil
    end

    it "refuses to copy from a source another project owns" do
      post type_configuration_copy_copy_path(in_project_id: project, type_id: type.id, variant_id: ours.id, aspect:),
           params: { source_id: theirs.id }, as: :turbo_stream

      expect(response).not_to have_http_status(:found)
    end
  end

  describe "copying a workflow" do
    # Opened as a dialog, so there is no HTML template for it in either mount.
    it "opens the copy dialog" do
      get new_type_workflow_copy_path(in_project_id: project, type_id: type.id, variant_id: ours.id),
          as: :turbo_stream

      expect(response).to have_http_status(:ok)
    end

    # This was the escalation: the targets are written to, so an id naming another project's
    # variant must not be copied into.
    it "refuses to copy into a variant another project owns" do
      expect do
        post type_workflow_copy_from_variant_path(in_project_id: project, type_id: type.id, variant_id: ours.id),
             params: { target_variant_ids: [theirs.id] }, as: :turbo_stream
      end.not_to change { theirs.reload.own_workflows.count }
    end
  end

  # Screens administration alone has. These raised on an unknown permission rather than being
  # absent, because #authorize reached them before anything had turned the project away.
  describe "the screens a project has no page for" do
    it "gives 404 for choosing the projects a type is used in" do
      get edit_type_projects_path(in_project_id: project, type_id: type.id)

      expect(response).to have_http_status(:not_found)
    end

    it "gives 404 for activating a variant in new projects" do
      post make_default_type_variant_path(in_project_id: project, type_id: type.id, id: ours.id)

      expect(response).to have_http_status(:not_found)
    end

    it "leaves both of them to administration" do
      login_as create(:admin)

      get edit_type_projects_path(type_id: type.id)

      expect(response).to have_http_status(:ok)
    end
  end

  # Leaving one of these screens has to land on the list it was started from. types_path carries no
  # project, so naming it while scoped appended the project as a query parameter and pointed at an
  # administration URL the caller cannot open.
  describe "leaving a variant screen" do
    it "returns to the project's own list after deleting a variant" do
      variant = create(:project_owned_type_variant, type:, project:, variant_name: "Leaving")

      delete type_variant_path(in_project_id: project, type_id: type.id, id: variant.id)

      expect(response).to redirect_to(project_settings_work_packages_types_path(project))
    end

    it "returns to administration's list when administration deletes one" do
      login_as create(:admin)
      global = create(:type_variant, type:, variant_name: "Global leaving")

      delete type_variant_path(type_id: type.id, id: global.id)

      expect(response).to redirect_to(types_path)
    end
  end

  # The steps carry the form the reader has come to fill in — the workflow matrix widest of all —
  # and the project menu leaves it too little room on a laptop. The breadcrumb still says where
  # this is, so the trail does not depend on the menu.
  describe "the wizard's chrome" do
    it "leaves the project menu out" do
      get type_creation_wizard_path(in_project_id: project, type_id: type.id, variant_id: ours.id,
                                    step: "workflows")

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('id="main-menu"')
    end

    it "still says where it is" do
      get type_creation_wizard_path(in_project_id: project, type_id: type.id, variant_id: ours.id,
                                    step: "workflows")

      expect(response.body).to include(project_settings_work_packages_types_path(project))
    end
  end

  describe "the wizard's steps" do
    # A variant only this project uses is never activated anywhere else, so the step that
    # picks projects must not be reachable, sidebar or URL.
    it "gives 404 for the projects step" do
      get type_creation_wizard_path(in_project_id: project, type_id: type.id, variant_id: ours.id,
                                    step: "projects")

      expect(response).to have_http_status(:not_found)
    end

    # Walked one by one: the wizard renders a different editor per step, and only the workflows
    # one turned out to reach for the matrix.
    it "serves every step it has" do
      WorkPackageTypes::Wizard::Steps.available_for(ours).each do |step|
        get type_creation_wizard_path(in_project_id: project, type_id: type.id, variant_id: ours.id, step:)

        expect(response).to have_http_status(:ok), "expected the #{step} step to render"
      end
    end

    # Advancing has to skip the step the variant does not have, or the wizard walks the user
    # straight into a 404 on the step after workflows.
    it "advances past the workflows step to the one after projects" do
      patch type_creation_wizard_path(in_project_id: project, type_id: type.id, variant_id: ours.id,
                                      step: "workflows")

      expect(response).to redirect_to(
        type_creation_wizard_path(in_project_id: project, type_id: type.id, variant_id: ours.id, step: "pdf")
      )
    end

    it "still serves the steps it does have" do
      get type_creation_wizard_path(in_project_id: project, type_id: type.id, variant_id: ours.id,
                                    step: "defaults")

      expect(response).to have_http_status(:ok)
    end
  end
end
