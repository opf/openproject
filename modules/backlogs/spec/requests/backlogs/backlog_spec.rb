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

    it "renders the sortable lists configuration on the backlogs turbo frame" do
      get "/projects/#{project.identifier}/backlogs/backlog"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-controller="backlogs--list-refresh backlogs--split-view-sync sortable-lists"')
      expect(response.body).to include(
        %(data-sortable-lists-move-url-template-value="/projects/#{project.identifier}/backlogs/work_packages/{id}/move")
      )
      expect(response.body).to include(
        %(data-sortable-lists-collection-move-url-value="/projects/#{project.identifier}/backlogs/work_packages/move")
      )
      expect(response.body).to include(
        'data-sortable-lists-move-announcement-scope-value="js.backlogs.announcements"'
      )
      expect(response.body).to include(
        "data-sortable-lists-sortable-lists--list-outlet=" \
        "\"#backlogs_container [data-controller~=&#39;sortable-lists--list&#39;]\""
      )
      expect(response.body).to include(
        "data-sortable-lists-sortable-lists--item-outlet=" \
        "\"#backlogs_container [data-controller~=&#39;sortable-lists--item&#39;]\""
      )
      expect(response.body).to include(
        "data-sortable-lists-sortable-lists--scrollable-outlet=" \
        "\"#backlogs_container [data-controller~=&#39;sortable-lists--scrollable&#39;]\""
      )
    end

    it "passes all=true to the frame src but keeps it off the move URL template" do
      get "/projects/#{project.identifier}/backlogs/backlog", params: { all: "1" }

      expect(response).to have_http_status(:ok)
      expect(response).to have_turbo_frame "backlogs_container",
                                           src: "/projects/#{project.identifier}/backlogs/backlog?all=true"
      # The move endpoint ignores the filter, so it stays out of the move URL
      # template even when the backlog itself is filtered.
      expect(response.body).to include(
        %(data-sortable-lists-move-url-template-value="/projects/#{project.identifier}/backlogs/work_packages/{id}/move")
      )
    end

    context "with a Turbo Frame request" do
      it "renders the sprint planning list partial" do
        get "/projects/#{project.identifier}/backlogs/backlog", headers: { "Turbo-Frame" => "backlogs_container" }

        expect(response).to have_http_status(:ok)
        expect(response).to render_template("backlogs/backlog/_backlog_list")

        expect(response).to have_turbo_frame "backlogs_container"
        expect(response).to have_no_turbo_frame "content-bodyRight"
        expect(response.body.scan('data-controller="sortable-lists--scrollable"').size).to eq(2)
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

      it "uses the inbox border box as a backlogs list target" do
        get "/projects/#{project.identifier}/backlogs/backlog", headers: { "Turbo-Frame" => "backlogs_container" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(%(id="inbox_project_#{project.id}"))
        expect(response.body).to include('data-controller="sortable-lists--list"')
        expect(response.body).to include('data-sortable-lists--list-type-value="inbox"')
        expect(response.body).not_to include('data-sortable-lists--list-id-value="inbox"')
      end

      context "with backlog buckets" do
        shared_let(:backlog_bucket) { create(:backlog_bucket, project:) }

        it "uses each backlog bucket border box as a backlogs list target" do
          get "/projects/#{project.identifier}/backlogs/backlog", headers: { "Turbo-Frame" => "backlogs_container" }

          expect(response).to have_http_status(:ok)
          expect(response.body).to include(%(data-test-selector="backlog-bucket-#{backlog_bucket.id}"))
          expect(response.body).to include('data-sortable-lists--list-type-value="backlog_bucket"')
          expect(response.body).to include(%(data-sortable-lists--list-id-value="#{backlog_bucket.id}"))
        end
      end

      context "when a bucket filter hides the inbox" do
        shared_let(:backlog_bucket) { create(:backlog_bucket, project:) }

        it "still renders the shared selection description" do
          get "/projects/#{project.identifier}/backlogs/backlog",
              params: { bucket_ids: [backlog_bucket.id] },
              headers: { "Turbo-Frame" => "backlogs_container" }

          expect(response).to have_http_status(:ok)
          # The inbox itself is filtered out...
          expect(response.body).not_to include(%(id="inbox_project_#{project.id}"))
          # ...but the shared description survives for the lists that remain.
          expect(response.body).to include(%(id="#{Backlogs::SelectionDescriptionComponent::DESCRIPTION_ID}"))
        end
      end

      # With every card fixed, opting in would only cost the viewer their
      # Space, arrow, Home/End and Ctrl/Cmd+A keys.
      context "when the user cannot manage sprint items" do
        shared_let(:viewer_role) do
          create(:project_role, permissions: %i[view_sprints view_work_packages])
        end
        shared_let(:viewer) { create(:user, member_with_roles: { project => viewer_role }) }

        current_user { viewer }

        # A full page load, not a frame request: the sortable root and its
        # selection values live on the wrapper in show.html.erb, which a
        # Turbo-Frame request never renders.
        it "does not enable batch selection" do
          get "/projects/#{project.identifier}/backlogs/backlog"

          expect(response).to have_http_status(:ok)
          expect(response.body).to include('data-sortable-lists-selection-enabled-value="false"')
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
