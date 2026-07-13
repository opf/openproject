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

RSpec.describe "Backlogs::Backlog", :skip_csrf, type: :rails_request do
  include Turbo::TestAssertions

  shared_let(:type_feature) { create(:type_feature) }
  shared_let(:type_task) { create(:type_task) }
  shared_let(:user) { create(:admin) }
  shared_let(:project) { create(:project) }
  shared_let(:status)  { create(:status, name: "status 1", is_default: true) }
  shared_let(:sprint)  { create(:sprint, project:) }
  shared_let(:story) { create(:work_package, status:, sprint:, project:) }

  current_user { user }

  describe "GET #index" do
    it "redirects to backlog" do
      get "/projects/#{project.identifier}/backlogs"

      expect(response).to redirect_to("/projects/#{project.identifier}/backlogs/backlog")
    end

    context "with a Turbo Frame request" do
      it "redirects to backlog" do
        get "/projects/#{project.identifier}/backlogs", headers: { "Turbo-Frame" => "backlogs_container" }

        expect(response).to redirect_to("/projects/#{project.identifier}/backlogs/backlog")
      end
    end
  end

  describe "GET #backlog" do
    it "is successful" do
      get "/projects/#{project.identifier}/backlogs/backlog"

      expect(response).to have_http_status(:ok)
      expect(response).to render_template("backlogs/backlog/show")
      expect(response).to have_turbo_frame "backlogs_container",
                                           src: "/projects/#{project.identifier}/backlogs/backlog"
      expect(response).to have_turbo_frame "content-bodyRight"
    end

    it "passes all=true on the backlog turbo frame when requested" do
      get "/projects/#{project.identifier}/backlogs/backlog", params: { all: "1" }

      expect(response).to have_http_status(:ok)
      expect(response).to have_turbo_frame "backlogs_container",
                                           src: "/projects/#{project.identifier}/backlogs/backlog?all=true"
    end

    context "with a Turbo Frame request" do
      it "renders the sprint planning list partial" do
        get "/projects/#{project.identifier}/backlogs/backlog", headers: { "Turbo-Frame" => "backlogs_container" }

        expect(response).to have_http_status(:ok)
        expect(response).to render_template("backlogs/backlog/_backlog_list")

        expect(response).to have_turbo_frame "backlogs_container"
        expect(response).to have_no_turbo_frame "content-bodyRight"
      end

      context "with no sprints available" do
        before do
          allow(Sprint)
            .to receive(:for_project)
            .with(project)
            .and_return(Sprint.none)
        end

        it "still renders the sprint planning container for turbo-frame requests" do
          get "/projects/#{project.identifier}/backlogs/backlog", headers: { "Turbo-Frame" => "backlogs_container" }

          expect(response).to have_http_status(:ok)
          expect(response.body).to include('id="owner_backlogs_container"')
          expect(response.body).to include('id="sprint_backlogs_container"')
        end
      end
    end
  end

  describe "GET #details" do
    it "is successful" do
      get "/projects/#{project.identifier}/backlogs/backlog/details/#{story.id}"

      expect(response).to have_http_status(:ok)
      expect(response).to render_template("backlogs/backlog/show")

      expect(response).to have_turbo_frame "backlogs_container",
                                           src: "/projects/#{project.identifier}/backlogs/backlog"
      expect(response).to have_turbo_frame "content-bodyRight"
    end

    context "with a Turbo Frame request" do
      it "renders the split view" do
        get "/projects/#{project.identifier}/backlogs/backlog/details/#{story.id}",
            headers: { "Turbo-Frame" => "content-bodyRight" }

        expect(response).to have_http_status(:ok)
        expect(response).to render_template("work_packages/split_view")

        expect(response).to have_turbo_frame "content-bodyRight"
        expect(response).to have_no_turbo_frame "backlogs_container"
      end
    end
  end
end
