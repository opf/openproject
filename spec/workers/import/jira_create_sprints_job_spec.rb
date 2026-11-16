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

RSpec.describe Import::JiraCreateSprintsJob do
  let(:jira) { create(:jira) }
  let(:author) { create(:user) }
  let(:jira_import) { create(:jira_import, jira:, author:) }
  let(:jira_client) { instance_double(Import::JiraClient) }
  let(:fields) do
    [{ "id" => "customfield_10102", "custom" => true,
       "schema" => { "type" => "array", "custom" => "com.pyxis.greenhopper.jira:gh-sprint" } }]
  end

  let(:demo) { stage_project("10000", "DEMO") }
  let(:aauv) { stage_project("10001", "AAUV") }

  def stage_project(origin_id, key)
    jira_project = create(:jira_project, jira_import:, origin_id:, payload: { "id" => origin_id, "key" => key })
    project = create(:project, enabled_module_names: %w[work_package_tracking])
    create(:jira_open_project_reference, jira_import:,
                                         op_entity_id: project.id, op_entity_class: "Project",
                                         jira_entity_id: jira_project.id, jira_entity_class: "Import::JiraProject")
    jira_project
  end

  def op_project(jira_project)
    jira_import.find_op_leg!(jira_project)
  end

  def stage_issue(jira_project, *sprint_ids)
    create(:jira_issue, jira_import:, jira_project:,
                        payload: { "fields" => { "customfield_10102" => sprint_ids.map { { "id" => it } } } })
  end

  def stage_sprint(id, **payload)
    create(:jira_sprint, jira_import:, origin_id: id.to_s,
                         payload: { "id" => id, "name" => "Sprint #{id}", "state" => "future" }.merge(payload.stringify_keys))
  end

  def created_sprint(id)
    jira_import.find_op_leg(Import::JiraSprint.find_by!(jira_import:, origin_id: id.to_s))
  end

  subject(:perform) { described_class.perform_now(jira_import.id) }

  before do
    allow(Import::JiraClient).to receive(:new).and_return(jira_client)
    allow(jira_client).to receive(:fields).and_return(fields)
  end

  describe "#perform" do
    it "creates a closed sprint with its dates, timestamps and goal" do
      stage_issue(demo, 2)
      stage_sprint(2, name: "Sample Sprint 1", state: "closed", goal: " Ship it ",
                      startDate: "2025-12-21T23:23:28.766Z", endDate: "2026-01-04T23:23:28.766Z",
                      activatedDate: "2025-12-21T23:23:28.766Z", completeDate: "2026-01-04T22:03:28.766Z")

      perform

      sprint = created_sprint(2)
      expect(sprint).to have_attributes(
        project: op_project(demo), name: "Sample Sprint 1", status: "completed",
        start_date: Date.new(2025, 12, 21), finish_date: Date.new(2026, 1, 4),
        started_at: Time.zone.parse("2025-12-21T23:23:28.766Z"), completed_at: Time.zone.parse("2026-01-04T22:03:28.766Z")
      )
      expect(sprint.goal_text_for(op_project(demo))).to eq("Ship it")
    end

    it "creates future and active sprints" do
      stage_issue(demo, 1, 3)
      stage_sprint(1, state: "active", startDate: "2026-11-02T09:00:00.000Z", endDate: "2026-11-16T17:00:00.000Z")
      stage_sprint(3, state: "future")

      perform

      expect(created_sprint(1).status).to eq("active")
      expect(created_sprint(3)).to have_attributes(status: "in_planning", start_date: nil, finish_date: nil)
    end

    it "skips a sprint no imported issue references" do
      stage_issue(demo, 1)
      stage_sprint(1)
      stage_sprint(9)

      expect { perform }.to change(Sprint, :count).by(1)
      expect(created_sprint(9)).to be_nil
    end

    it "gives a sprint spanning projects to the project with the most issues" do
      stage_issue(demo, 7)
      stage_issue(aauv, 7)
      stage_issue(aauv, 7)
      stage_sprint(7)

      perform

      expect(created_sprint(7).project).to eq(op_project(aauv))
    end

    it "gives a sprint with a tie to the project whose key sorts first" do
      stage_issue(demo, 9)
      stage_issue(aauv, 9)
      stage_sprint(9)

      perform

      expect(created_sprint(9).project).to eq(op_project(aauv))
    end

    it "counts an issue once even if it lists the sprint several times" do
      stage_issue(demo, 7, 7, 7)
      stage_issue(aauv, 7)
      stage_issue(aauv, 7)
      stage_sprint(7)

      perform

      expect(created_sprint(7).project).to eq(op_project(aauv))
    end

    it "enables the backlogs module in every project that owns or receives the sprint" do
      stage_issue(demo, 7)
      stage_issue(aauv, 7)
      stage_sprint(7)

      perform

      expect([op_project(demo), op_project(aauv)].map { it.reload.module_enabled?(:backlogs) }).to all(be(true))
    end

    it "allows multiple active sprints in a project that owns several" do
      stage_issue(demo, 1, 7)
      dates = { startDate: "2026-11-02T09:00:00.000Z", endDate: "2026-11-16T17:00:00.000Z" }
      stage_sprint(1, state: "active", **dates)
      stage_sprint(7, state: "active", **dates)

      perform

      expect([created_sprint(1).status, created_sprint(7).status]).to eq(%w[active active])
      expect(op_project(demo).reload).to be_allow_multiple_active_sprints
    end

    it "leaves the setting alone in a project with one active sprint" do
      stage_issue(demo, 1)
      stage_sprint(1, state: "active", startDate: "2026-11-02T09:00:00.000Z", endDate: "2026-11-16T17:00:00.000Z")

      perform

      expect(op_project(demo).reload).not_to be_allow_multiple_active_sprints
    end

    it "imports an active sprint without dates as in planning" do
      stage_issue(demo, 1)
      stage_sprint(1, state: "active", startDate: "2026-11-02T09:00:00.000Z")

      perform

      expect(created_sprint(1).status).to eq("in_planning")
    end

    it "keeps the planned dates of a Jira server outside UTC" do
      stage_issue(demo, 3)
      stage_sprint(3, startDate: "2026-11-02T09:00:00.000+10:00", endDate: "2026-11-16T17:00:00.000-08:00")

      perform

      expect(created_sprint(3)).to have_attributes(start_date: Date.new(2026, 11, 2), finish_date: Date.new(2026, 11, 16))
    end

    it "moves a finish date before the start date to the start date" do
      stage_issue(demo, 3)
      stage_sprint(3, startDate: "2026-11-16T09:00:00.000Z", endDate: "2026-11-02T17:00:00.000Z")

      perform

      expect(created_sprint(3)).to have_attributes(start_date: Date.new(2026, 11, 16), finish_date: Date.new(2026, 11, 16))
    end

    it "imports a malformed timestamp as no date" do
      stage_issue(demo, 4)
      stage_sprint(4, state: "closed", startDate: "2026-13-45T09:00:00.000Z", endDate: "not a date",
                      completeDate: "2026-11-02T99:00:00.000Z")

      perform

      expect(created_sprint(4)).to have_attributes(start_date: nil, finish_date: nil, completed_at: nil)
    end

    it "names a sprint without a name after its Jira id" do
      stage_issue(demo, 6)
      stage_sprint(6, name: nil)

      perform

      expect(created_sprint(6).name).to eq("Sprint 6")
    end

    it "truncates a goal longer than a sprint goal may be" do
      stage_issue(demo, 5)
      stage_sprint(5, goal: "x" * 601)

      perform

      expect(created_sprint(5).goal_text_for(op_project(demo)).length).to eq(SprintGoal::TEXT_MAX_LENGTH)
    end

    it "creates no goal for a blank one" do
      stage_issue(demo, 5)
      stage_sprint(5, goal: "  ")

      expect { perform }.not_to change(SprintGoal, :count)
    end

    it "resumes after the last sprint created before an interruption" do
      stage_issue(demo, 1, 2)
      first = stage_sprint(1)
      stage_sprint(2)
      jira_import.set_job_cursor(described_class.new(jira_import.id), first.id)

      expect { perform }.to change(Sprint, :count).by(1)
      expect(created_sprint(2)).to be_present
    end

    it "stores the Jira origin of the sprint" do
      stage_issue(demo, 2)
      stage_sprint(2, originBoardId: 4)

      perform

      expect(created_sprint(2)).to have_attributes(
        origin_source: "jira_data_center", origin_host: "https://jira-software.local/", origin_id: "2",
        origin_url: "https://jira-software.local/secure/RapidBoard.jspa?rapidView=4&view=reporting&chart=sprintRetrospective&sprint=2"
      )
    end

    it "links a sprint without origin board to its REST resource" do
      stage_issue(demo, 2)
      stage_sprint(2)

      perform

      expect(created_sprint(2).origin_url).to eq("https://jira-software.local/rest/agile/1.0/sprint/2")
    end

    context "when an earlier import created the sprint" do
      let(:earlier_project) { create(:project) }
      let!(:earlier_sprint) do
        create(:sprint, project: earlier_project, name: "Earlier", origin_source: "jira_data_center",
                        origin_host: jira.url, origin_id: "7", origin_url: "#{jira.url}rest/agile/1.0/sprint/7")
      end

      before do
        stage_issue(aauv, 7)
        stage_sprint(7, goal: "Ship it")
      end

      it "reuses the sprint without changing it" do
        expect { perform }.not_to change(Sprint, :count)
        expect(created_sprint(7)).to eq(earlier_sprint)
        expect(earlier_sprint.reload).to have_attributes(project: earlier_project, name: "Earlier")
        expect(SprintGoal.where(sprint: earlier_sprint)).to be_empty
      end

      it "marks the reference as using an existing sprint" do
        perform

        reference = Import::JiraOpenProjectReference.find_by!(jira_import:, op_entity_class: "Sprint")
        expect(reference.uses_existing).to be(true)
      end

      it "enables the backlogs module in the importing project" do
        perform

        expect(op_project(aauv).reload.module_enabled?(:backlogs)).to be(true)
      end
    end

    it "does not reuse a sprint of another Jira instance" do
      create(:sprint, origin_source: "jira_data_center", origin_host: "https://other-jira.local/", origin_id: "7",
                      origin_url: "https://other-jira.local/rest/agile/1.0/sprint/7")
      stage_issue(demo, 7)
      stage_sprint(7)

      expect { perform }.to change(Sprint, :count).by(1)
      expect(created_sprint(7).project).to eq(op_project(demo))
    end
  end

  describe "#progress" do
    subject(:job) { described_class.new(jira_import.id) }

    it "returns zeros before the first sprint" do
      expect(job.progress).to eq({ current: 0, total: 0, percentage: 0 })
    end

    it "reports the sprints processed so far" do
      first = stage_sprint(1)
      stage_sprint(2)
      jira_import.set_job_cursor(job, first.id)

      expect(job.progress).to eq({ current: 1, total: 2, percentage: 50.0 })
    end
  end
end
