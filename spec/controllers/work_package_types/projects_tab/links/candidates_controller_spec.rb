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

RSpec.describe WorkPackageTypes::ProjectsTab::Links::CandidatesController do
  let(:project) { create(:project) }
  let(:type) { create(:type_bug) }
  let(:user) { create(:admin) }

  before do
    login_as user
  end

  def node_payload(project)
    { path: [project.name], nodeId: project.id.to_s }.to_json
  end

  describe "GET index" do
    let!(:child) { create(:project, name: "Child", parent: project) }

    it "renders the project tree the dialog picks from" do
      get :index, params: { type_id: type.id, name: "project_ids" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(project.name).and include(child.name)
    end

    it "narrows to the matches and the branches leading to them" do
      get :index, params: { type_id: type.id, name: "project_ids", query: "Child" }

      expect(response.body).to include(child.name).and include(project.name)
    end

    it "leaves out projects that match nothing" do
      other = create(:project, name: "Unrelated")

      get :index, params: { type_id: type.id, name: "project_ids", query: "Child" }

      expect(response.body).not_to include(other.name)
    end

    it "matches a project by its identifier" do
      create(:project, name: "Bookshop", identifier: "libris-nova")

      get :index, params: { type_id: type.id, name: "project_ids", query: "libris" }

      expect(response.body).to include("Bookshop")
    end
  end
end
