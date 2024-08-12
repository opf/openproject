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

require "rails_helper"

RSpec.describe Projects::IdentifierController do
  let(:project) { create(:project) }

  current_user { create(:admin) }
  render_views

  describe "update" do
    it "sets the project identifier to the provided value" do
      put :update, params: { project_id: project.id, project: { identifier: "new-identifier" } }

      # Upon success, the user is redirected to the general project settings page
      expect(response).to have_http_status(:redirect)
      expect(project.reload.identifier).to eq("new-identifier")
    end

    context "with an invalid identifier" do
      it "does not change the project identifier and correctly renders the view" do
        previous_identifier = project.identifier
        put :update, params: { project_id: project.id, project: { identifier: "bad identifier" } }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Identifier is invalid")
        expect(project.reload.identifier).to eq(previous_identifier)
      end
    end
  end
end
