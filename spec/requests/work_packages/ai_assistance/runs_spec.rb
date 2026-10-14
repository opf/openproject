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

RSpec.describe "AI Assistance runs", :skip_csrf, type: :rails_request, with_flag: { ai_assistance: true } do
  include_context "with an available LLM for AI Assistance"

  shared_let(:project) { create(:project) }
  shared_let(:skill) { create(:ai_assistant_skill) }

  let(:permissions) { %i[view_work_packages use_ai_assistance] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:work_package) { create(:work_package, project:) }

  current_user { user }

  describe "GET show" do
    let(:run) { create(:ai_assistant_run, :finished, skill:, user:, work_package:) }

    it "opens the run dialog" do
      get "/work_packages/#{work_package.id}/ai_assistance/runs/#{run.id}", as: :turbo_stream

      expect(response).to have_turbo_stream(action: "dialog")
    end

    context "for another user's run" do
      let(:run) { create(:ai_assistant_run, :finished, skill:, work_package:) }

      it "responds with not found" do
        get "/work_packages/#{work_package.id}/ai_assistance/runs/#{run.id}", as: :turbo_stream

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET poll" do
    let(:run) { create(:ai_assistant_run, skill:, user:, work_package:, status: "ai_running") }

    it "has no content while the review runs" do
      get "/work_packages/#{work_package.id}/ai_assistance/runs/#{run.id}/poll"

      expect(response).to have_http_status(:no_content)
    end

    it "replaces the run once it is finished" do
      run.update!(status: "finished")

      get "/work_packages/#{work_package.id}/ai_assistance/runs/#{run.id}/poll"

      expect(response).to have_http_status(:ok)
      expect(response).to have_turbo_stream(action: "replace", target: "ai-assistance-run-#{run.id}")
    end
  end

  describe "GET index" do
    before do
      create(:ai_assistant_run, :finished, skill:, user:, work_package:)
      create(:ai_assistant_run, :finished, skill:, work_package:)
    end

    it "lists only the user's runs" do
      get "/work_packages/#{work_package.id}/ai_assistance/runs", as: :turbo_stream

      expect(response).to have_turbo_stream(action: "dialog")
      expect(response.body.scan("/ai_assistance/runs/").size).to eq(1)
    end
  end

  describe "POST dismiss" do
    let(:run) { create(:ai_assistant_run, :finished, skill:, user:, work_package:) }
    let(:finding) { create(:ai_assistant_run_finding, run:) }

    it "dismisses the finding with the reason" do
      post "/work_packages/#{work_package.id}/ai_assistance/runs/#{run.id}/findings/#{finding.id}/dismiss",
           params: { reason: "wrong" }, as: :turbo_stream

      expect(finding.reload).to have_attributes(state: "dismissed", dismiss_reason: "wrong")
      expect(response).to have_turbo_stream(action: "replace")
    end

    it "ignores an unknown reason" do
      post "/work_packages/#{work_package.id}/ai_assistance/runs/#{run.id}/findings/#{finding.id}/dismiss",
           params: { reason: "bored" }, as: :turbo_stream

      expect(finding.reload).to have_attributes(state: "dismissed", dismiss_reason: nil)
    end
  end
end
