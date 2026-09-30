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

RSpec.describe "Creating a workflow for a project-owned variant", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }
  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:variant) { create(:project_owned_type_variant, type:, project:, variant_name: "Internal") }

  shared_let(:admin) { create(:admin) }
  shared_let(:project_admin) do
    create(:user, member_with_permissions: { project => %i[manage_project_variants] })
  end
  shared_let(:outsider) { create(:user, member_with_permissions: { other_project => %i[manage_project_variants] }) }

  let(:in_project) { "/projects/#{project.identifier}/settings/work_packages/types/#{type.id}/variants/#{variant.id}" }
  let(:in_administration) { type_variant_workflow_path(type_id: type.id, variant_id: variant.id) }

  def create_workflow(path, name: "Release flow")
    post path, params: { workflow: { name: } }
  end

  describe "inside a project" do
    before { login_as project_admin }

    it "has no page for starting one" do
      expect { get "#{in_project}/workflow/configure_dialog", as: :turbo_stream }
        .to raise_error(ActionController::RoutingError)
    end

    it "has no route for the create itself" do
      expect { create_workflow("#{in_project}/workflow") }.to raise_error(ActionController::RoutingError)
    end
  end

  describe "in administration" do
    before { login_as admin }

    it "opens the dialog" do
      get configure_dialog_type_variant_workflow_path(type_id: type.id, variant_id: variant.id), as: :turbo_stream

      expect(response).to have_http_status(:ok)
    end

    it "creates a workflow the project owns and assigns it to the variant" do
      expect { create_workflow(in_administration) }.to change(Workflow, :count).by(1)

      created = Workflow.find_by(name: "Release flow")
      expect(response).to redirect_to(edit_workflow_path(created))
      expect(created.project).to eq(project)
      expect(variant.reload.workflow).to eq(created)
    end

    it "may reuse a name administration already holds" do
      create(:named_workflow, name: "Release flow")

      expect { create_workflow(in_administration) }.to change(Workflow, :count).by(1)

      expect(Workflow.owned_by(project).find_by(name: "Release flow")).to be_present
    end
  end

  it "is refused a member of another project" do
    login_as outsider

    get edit_project_type_variant_workflow_path(project_id: project, type_id: type.id, variant_id: variant.id)

    expect(response).not_to have_http_status(:ok)
  end
end
