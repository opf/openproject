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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

RSpec.describe "GET work packages export_dialog", type: :rails_request do
  let(:query_project) { create(:project) }
  let(:other_project) { create(:project) }
  let(:query_owner) { create(:user) }
  let(:query) { create(:public_query, project: query_project, user: query_owner) }
  let(:permissions) { %i[view_work_packages export_work_packages] }
  let(:modal_id) { WorkPackages::Exports::ModalDialogComponent::MODAL_ID }

  current_user do
    create(:user,
           member_with_permissions: {
             query_project => permissions,
             other_project => permissions
           })
  end

  def get_export_dialog(project = query_project, params: { query_id: query.id })
    path = project ? "/projects/#{project.identifier}/work_packages/export_dialog" : "/work_packages/export_dialog"
    get path, params:, headers: { "Accept" => "text/vnd.turbo-stream.html" }
  end

  shared_examples "renders the export dialog" do
    it "responds with a turbo stream rendering the export dialog", :aggregate_failures do
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include(modal_id)
    end
  end

  context "when the query belongs to the project in the URL" do
    before { get_export_dialog(query_project) }

    include_examples "renders the export dialog"
  end

  context "when the query belongs to a different project than the one in the URL" do
    # Regression test https://community.openproject.org/projects/OP/work_packages/OP-19478
    before { get_export_dialog(other_project) }

    include_examples "renders the export dialog"

    it "points the export form at the query's own project, not the URL project" do
      expect(response.body).to include("/projects/#{query_project.identifier}/work_packages")
      expect(response.body).not_to include("/projects/#{other_project.identifier}/work_packages")
    end
  end

  context "when exporting the user's own private query" do
    let(:query) { create(:private_query, project: query_project, user: current_user) }

    before { get_export_dialog(query_project) }

    include_examples "renders the export dialog"
  end

  context "when no query_id is given (unsaved default query)" do
    before { get_export_dialog(query_project, params: {}) }

    include_examples "renders the export dialog"
  end

  context "with a global (project-less) query" do
    let(:query) { create(:global_query, user: query_owner) }

    context "when opened from the global work package list" do
      before { get_export_dialog(nil) }

      include_examples "renders the export dialog"
    end

    context "when opened from a project work package list" do
      before { get_export_dialog(other_project) }

      include_examples "renders the export dialog"
    end
  end

  context "when a title is passed" do
    before { get_export_dialog(query_project, params: { query_id: query.id, title: "ZZUniqueExportTitle" }) }

    it "carries the title into the dialog's export parameters", :aggregate_failures do
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ZZUniqueExportTitle")
    end
  end

  context "when the query is another user's private query" do
    let(:query) { create(:private_query, project: query_project, user: query_owner) }

    before { get_export_dialog(query_project) }

    it "responds with a 404" do
      expect(response).to have_http_status(:not_found)
    end
  end

  context "when the query belongs to a project the user cannot view" do
    # The user may export in other_project but is not a member of query_project,
    # so a query living there must not be exportable from anywhere.
    current_user do
      create(:user, member_with_permissions: { other_project => %i[view_work_packages export_work_packages] })
    end

    before { get_export_dialog(other_project) }

    it "responds with a 404" do
      expect(response).to have_http_status(:not_found)
    end
  end

  context "when the query does not exist" do
    before { get_export_dialog(query_project, params: { query_id: 0 }) }

    it "responds with a 404" do
      expect(response).to have_http_status(:not_found)
    end
  end

  context "when the user lacks the export permission" do
    let(:permissions) { %i[view_work_packages] }

    before { get_export_dialog(query_project) }

    it "responds with a 403" do
      expect(response).to have_http_status(:forbidden)
    end
  end
end
