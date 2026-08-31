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

require "rails_helper"

RSpec.describe Backlogs::BucketsController do
  let(:permissions) { %i[view_sprints view_work_packages create_sprints] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:project) { create(:project) }
  let!(:backlog_bucket) { create(:backlog_bucket, project:) }

  current_user { user }

  describe "POST #create" do
    let(:params) do
      { project_id: project.id, backlog_bucket: { name: "New bucket" } }
    end

    it "creates a bucket and redirects to backlogs" do
      post :create, format: :turbo_stream, params: params

      expect(response).to be_successful
      expect(response.body).to have_turbo_stream(
        action: "redirect_to",
        url: project_backlogs_backlog_path(project)
      )
      expect(flash[:notice]).to eq(I18n.t(:notice_successful_create))
    end

    context "when all=true is passed" do
      it "redirects to backlogs preserving the all param" do
        post :create, format: :turbo_stream, params: params.merge(all: 1)

        expect(response.body).to have_turbo_stream(
          action: "redirect_to",
          url: project_backlogs_backlog_path(project, all: true)
        )
      end
    end
  end

  describe "PUT #update" do
    let(:params) do
      { project_id: project.id, id: backlog_bucket.id, backlog_bucket: { name: "Renamed bucket" } }
    end

    it "updates a bucket and redirects to backlogs" do
      put :update, format: :turbo_stream, params: params

      expect(response).to be_successful
      expect(response.body).to have_turbo_stream(
        action: "redirect_to",
        url: project_backlogs_backlog_path(project)
      )
      expect(backlog_bucket.reload.name).to eq("Renamed bucket")
      expect(flash[:notice]).to eq(I18n.t(:notice_successful_update))
    end

    context "when all=true is passed" do
      it "redirects to backlogs preserving the all param" do
        put :update, format: :turbo_stream, params: params.merge(all: 1)

        expect(response.body).to have_turbo_stream(
          action: "redirect_to",
          url: project_backlogs_backlog_path(project, all: true)
        )
      end
    end
  end

  describe "DELETE #destroy" do
    let(:params) do
      { project_id: project.id, id: backlog_bucket.id }
    end

    it "deletes a bucket and redirects to backlogs" do
      delete :destroy, format: :turbo_stream, params: params

      expect(response).to be_successful
      expect(response.body).to have_turbo_stream(
        action: "redirect_to",
        url: project_backlogs_backlog_path(project)
      )
      expect(flash[:notice]).to eq(I18n.t(:notice_successful_delete))
    end

    context "when all=true is passed" do
      it "redirects to backlogs preserving the all param" do
        delete :destroy, format: :turbo_stream, params: params.merge(all: 1)

        expect(response.body).to have_turbo_stream(
          action: "redirect_to",
          url: project_backlogs_backlog_path(project, all: true)
        )
      end
    end
  end
end
