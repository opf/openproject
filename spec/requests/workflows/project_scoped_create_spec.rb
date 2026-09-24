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

RSpec.describe "Creating a workflow from inside a project", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }
  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:variant) { create(:project_owned_type_variant, type:, project:, variant_name: "Internal") }

  shared_let(:project_admin) do
    create(:user, member_with_permissions: { project => %i[manage_project_variants] })
  end
  shared_let(:outsider) { create(:user, member_with_permissions: { other_project => %i[manage_project_variants] }) }

  let(:path_args) { { in_project_id: project, type_id: type.id, variant_id: variant.id } }

  def create_workflow(name: "Release flow")
    post type_workflow_path(**path_args), params: { workflow: { name: } }
  end

  describe "a member with manage_project_variants" do
    before { login_as project_admin }

    it "opens the dialog" do
      get create_dialog_type_workflow_path(**path_args), as: :turbo_stream

      expect(response).to have_http_status(:ok)
    end

    it "creates a workflow the project owns and assigns it to the variant" do
      expect { create_workflow }.to change(Workflow, :count).by(1)

      expect(response).to redirect_to(edit_type_workflow_path(**path_args))

      created = Workflow.find_by(name: "Release flow")
      expect(created.project).to eq(project)
      expect(variant.reload.workflow).to eq(created)
    end

    it "may reuse a name administration already holds" do
      create(:named_workflow, name: "Release flow")

      expect { create_workflow }.to change(Workflow, :count).by(1)

      expect(Workflow.owned_by(project).find_by(name: "Release flow")).to be_present
    end

    it "is refused another project's variant" do
      foreign = create(:project_owned_type_variant, type:, project: other_project, variant_name: "Theirs")

      post type_workflow_path(in_project_id: project, type_id: type.id, variant_id: foreign.id),
           params: { workflow: { name: "Release flow" } }

      expect(response).to have_http_status(:not_found)
    end
  end

  it "is refused a member of another project" do
    login_as outsider

    expect { create_workflow }.not_to change(Workflow, :count)
    expect(response).not_to have_http_status(:redirect)
  end

  it "keeps the project in the path rather than a query parameter" do
    expect(type_workflow_path(**path_args)).to include("in-project/#{project.identifier}")
    expect(create_dialog_type_workflow_path(**path_args)).to include("in-project/#{project.identifier}")
    expect(type_workflow_path(**path_args)).not_to include("in_project_id=")
  end
end
