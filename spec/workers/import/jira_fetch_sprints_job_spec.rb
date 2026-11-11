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

RSpec.describe Import::JiraFetchSprintsJob do
  let(:jira) { create(:jira) }
  let(:author) { create(:user) }
  let(:jira_import) { create(:jira_import, jira:, author:) }
  let!(:jira_project) do
    create(:jira_project, jira_import:, origin_id: "10000", payload: { "id" => "10000", "key" => "DEMO", "name" => "Demo" })
  end
  let(:jira_client) { instance_double(Import::JiraClient) }
  let(:fields) do
    [
      { "id" => "summary", "custom" => false, "schema" => { "type" => "string", "system" => "summary" } },
      { "id" => "customfield_10102", "custom" => true,
        "schema" => { "type" => "array", "items" => "string",
                      "custom" => "com.pyxis.greenhopper.jira:gh-sprint", "customId" => 10102 } }
    ]
  end

  def sprint(id, state = "future")
    { "id" => id, "self" => "https://jira.example.com/rest/agile/1.0/sprint/#{id}", "state" => state,
      "name" => "Sprint #{id}", "originBoardId" => 1 }
  end

  # The pages JiraClient#board_sprint_pages yields: values, response and the position after the page.
  def sprint_pages(*sprints_per_page)
    start_at = 0
    sprints_per_page.map do |sprints|
      start_at += sprints.size
      [sprints, { "values" => sprints }, start_at]
    end.each
  end

  def sprint_field_value(id)
    "com.atlassian.greenhopper.service.sprint.Sprint@1f2[id=#{id},rapidViewId=36,state=FUTURE,name=Sprint, #{id}," \
      "startDate=<null>,endDate=<null>,completeDate=<null>,activatedDate=<null>,sequence=#{id},goal=<null>]"
  end

  def stage_board(id, type = "scrum")
    create(:jira_board, jira_import:, origin_id: id.to_s, type:)
  end

  def stage_issue(*sprint_ids)
    create(:jira_issue, jira_import:, jira_project:,
                        payload: { "fields" => { "customfield_10102" => sprint_ids.map { sprint_field_value(it) } } })
  end

  def staged_sprints
    Import::JiraSprint.where(jira_import:).order(Arel.sql("origin_id::integer")).pluck(:origin_id)
  end

  before do
    allow(Import::JiraClient).to receive(:new).and_return(jira_client)
    allow(jira_client).to receive(:fields).and_return(fields)
  end

  describe "#perform" do
    subject(:perform) { described_class.perform_now(jira_import.id) }

    context "with scrum and kanban boards" do
      let!(:scrum_board) { stage_board(1) }
      let!(:other_scrum_board) { stage_board(653) }

      before do
        stage_board(654, "kanban")
        allow(jira_client).to receive(:board_sprint_pages).with(board_id: "1")
          .and_return(sprint_pages([sprint(2, "closed"), sprint(1, "active")], [sprint(3)]))
        allow(jira_client).to receive(:board_sprint_pages).with(board_id: "653")
          .and_return(sprint_pages([sprint(1, "active"), sprint(7, "active")]))
      end

      it "stages the sprints of every page of every scrum board once" do
        perform

        expect(staged_sprints).to eq(%w[1 2 3 7])
      end

      it "does not ask a kanban board for sprints" do
        perform

        expect(jira_client).not_to have_received(:board_sprint_pages).with(board_id: "654")
      end

      it "raises a bad request for a scrum board" do
        error = Import::JiraClient::ApiError.new("bad request", status: 400, response_body: "", response_headers: {})
        allow(jira_client).to receive(:board_sprint_pages).with(board_id: "653").and_raise(error)

        expect { perform }.to raise_error(error)
      end

      it "skips a board deleted since it was fetched" do
        allow(jira_client).to receive(:board_sprint_pages).with(board_id: "653")
          .and_raise(Import::JiraClient::UnsupportedEndpointError, "no endpoint (status 404)")

        perform

        expect(staged_sprints).to eq(%w[1 2 3])
      end

      it "fetches only the sprints of issues that no board listed" do
        stage_issue(2, 11)
        allow(jira_client).to receive(:sprint).with("11").and_return(sprint(11))

        perform

        expect(staged_sprints).to eq(%w[1 2 3 7 11])
        expect(jira_client).to have_received(:sprint).once
      end
    end

    context "without boards" do
      it "fetches every sprint referenced by an issue" do
        stage_issue(2, 11)
        stage_issue(11)
        allow(jira_client).to receive(:sprint) { |id| sprint(id.to_i) }

        perform

        expect(staged_sprints).to eq(%w[2 11])
        expect(jira_client).to have_received(:sprint).twice
      end

      it "reads the sprint id when the goal contains separators" do
        value = "com.atlassian.greenhopper.service.sprint.Sprint@6a9ad71[activatedDate=<null>,autoStartStop=false," \
                "completeDate=<null>,endDate=<null>,goal=Ship, id=99, then review,id=8," \
                "incompleteIssuesDestinationId=<null>,name=Sprint B,rapidViewId=653,sequence=8,startDate=<null>," \
                "state=FUTURE,synced=false]"
        create(:jira_issue, jira_import:, jira_project:, payload: { "fields" => { "customfield_10102" => [value] } })
        allow(jira_client).to receive(:sprint).with("8").and_return(sprint(8))

        perform

        expect(staged_sprints).to eq(%w[8])
      end

      it "reads the JSON object form of the sprint field" do
        create(:jira_issue, jira_import:, jira_project:,
                            payload: { "fields" => { "customfield_10102" => [{ "id" => 5, "state" => "active" }] } })
        allow(jira_client).to receive(:sprint).with("5").and_return(sprint(5, "active"))

        perform

        expect(staged_sprints).to eq(%w[5])
      end

      it "skips a sprint Jira no longer has" do
        stage_issue(2, 11)
        allow(jira_client).to receive(:sprint).with("2")
          .and_raise(Import::JiraClient::UnsupportedEndpointError, "no endpoint (status 404)")
        allow(jira_client).to receive(:sprint).with("11").and_return(sprint(11))

        perform

        expect(staged_sprints).to eq(%w[11])
      end

      it "ignores issues without sprints" do
        create(:jira_issue, jira_import:, jira_project:, payload: { "fields" => { "customfield_10102" => nil } })
        create(:jira_issue, jira_import:, jira_project:, payload: { "fields" => { "summary" => "No sprint field" } })
        allow(jira_client).to receive(:sprint)

        perform

        expect(jira_client).not_to have_received(:sprint)
      end

      it "fetches nothing when the instance has no sprint field" do
        stage_issue(2)
        allow(jira_client).to receive(:fields).and_return(fields.first(1))
        allow(jira_client).to receive(:sprint)

        perform

        expect(jira_client).not_to have_received(:sprint)
      end

      context "with issues spread over several batches" do
        before do
          stub_const("#{described_class}::ISSUE_BATCH_SIZE", 1)
          allow(jira_client).to receive(:sprint) { |id| sprint(id.to_i) }
        end

        it "fetches a sprint referenced in several batches once" do
          stage_issue(11)
          stage_issue(11, 12)

          perform

          expect(staged_sprints).to eq(%w[11 12])
          expect(jira_client).to have_received(:sprint).twice
        end

        it "asks Jira once for a sprint it no longer has, however many batches reference it" do
          stage_issue(2)
          stage_issue(2, 11)
          allow(jira_client).to receive(:sprint).with("2")
            .and_raise(Import::JiraClient::UnsupportedEndpointError, "no endpoint (status 404)")

          perform

          expect(staged_sprints).to eq(%w[11])
          expect(jira_client).to have_received(:sprint).with("2").once
        end

        it "resumes after the last batch of issues scanned before an interruption" do
          stage_issue(2)
          scanned = stage_issue(11)
          stage_issue(12)
          job = described_class.new(jira_import.id)
          jira_import.set_job_cursor(job, { "phase" => "issues", "position" => scanned.id, "current" => 2, "total" => 3 })

          perform

          expect(jira_client).to have_received(:sprint).once
          expect(jira_client).to have_received(:sprint).with("12")
        end
      end
    end

    it "retries a board whose processing was cut short" do
      first_board = stage_board(1)
      stage_board(653)
      allow(jira_client).to receive(:board_sprint_pages).with(board_id: "1").and_return(sprint_pages([sprint(1, "active")]))
      allow(jira_client).to receive(:board_sprint_pages).with(board_id: "653")
        .and_raise(Import::JiraClient::ApiError.new("boom", status: 500, response_body: "", response_headers: {}))

      expect { perform }.to raise_error(Import::JiraClient::ApiError)
      expect(jira_import.get_job_cursor(described_class.new(jira_import.id))).to include("position" => first_board.id)

      allow(jira_client).to receive(:board_sprint_pages).with(board_id: "653").and_return(sprint_pages([sprint(7, "active")]))
      described_class.perform_now(jira_import.id)

      expect(staged_sprints).to eq(%w[1 7])
      expect(jira_client).to have_received(:board_sprint_pages).with(board_id: "1").once
    end

    it "resumes the board sweep after the last board fetched before an interruption" do
      first_board = stage_board(1)
      stage_board(653)
      job = described_class.new(jira_import.id)
      jira_import.set_job_cursor(job, { "phase" => "boards", "position" => first_board.id, "current" => 1, "total" => 2 })
      allow(jira_client).to receive(:board_sprint_pages).and_return(sprint_pages([sprint(7, "active")]))

      perform

      expect(jira_client).to have_received(:board_sprint_pages).once
      expect(jira_client).to have_received(:board_sprint_pages).with(board_id: "653")
    end
  end

  describe "#progress" do
    subject(:job) { described_class.new(jira_import.id) }

    it "returns zeros before the first board" do
      expect(job.progress).to eq({ current: 0, total: 0, percentage: 0 })
    end

    it "reports the position within the current phase" do
      jira_import.set_job_cursor(job, { "phase" => "boards", "position" => 5, "current" => 1, "total" => 4 })

      expect(job.progress).to eq({ current: 1, total: 4, percentage: 25.0 })
    end
  end
end
