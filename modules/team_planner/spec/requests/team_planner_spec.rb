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

RSpec.describe "Team planners", :skip_csrf, type: :rails_request, with_ee: %i[team_planner_view] do
  let(:project_a) { create(:project) }
  let(:project_b) { create(:project) }
  let(:user) do
    create(:user,
           member_with_permissions: {
             project_a => %i[view_work_packages view_team_planner manage_team_planner],
             project_b => %i[view_work_packages view_team_planner]
           })
  end
  let(:query) { create(:query, project: project_a, user:) }
  let(:other_user) { create(:user) }
  let!(:other_project_query) { create(:query, project: project_b, user: other_user, public: true) }

  before do
    create(:view_team_planner, query:)
    create(:view_team_planner, query: other_project_query)
    login_as(user)
  end

  describe "DELETE /projects/:project_id/team_planners/:id" do
    it "redirects with 303 See Other" do
      delete project_team_planner_path(project_a, query)
      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(project_team_planners_path(project_a))
    end

    it "does not delete team planners from another project" do
      delete project_team_planner_path(project_a, other_project_query)

      expect(response).to have_http_status(:not_found)
      expect(Query.exists?(other_project_query.id)).to be(true)
    end
  end
end
