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

RSpec.describe Import::JiraCreateRelationsJob, "for a link between two projects whose jobs run in parallel",
               with_settings: { work_packages_identifier: Setting::WorkPackageIdentifier::SEMANTIC } do
  include_context "with real database commits"
  include_context "with a jira demo issue"

  let(:other_jira_project) do
    create(:jira_project, jira_import:, origin_id: "10013",
                          payload: jira_project_payload.merge("id" => "10013", "key" => "KIWNEU1", "name" => "Kiwi project"))
  end

  # Jira lists the link on both issues, the fixture's DPPP-6 (10405) and KIWNEU1-1 (10019).
  let(:tests_link_type) { { "name" => "Tests", "inward" => "tested by", "outward" => "tests" } }
  let(:other_jira_issue_links) { [{ "type" => tests_link_type, "outwardIssue" => { "id" => "10405" } }] }
  let!(:other_jira_issue) do
    payload = jira_issue_payload.deep_merge("id" => "10019", "key" => "KIWNEU1-1",
                                            "fields" => { "issuelinks" => other_jira_issue_links })
    create(:jira_issue, jira_import:, jira_project: other_jira_project, origin_id: "10019", payload:)
  end

  before do
    create_project_role
    [jira_project, other_jira_project].each do |project|
      Import::JiraCreateProjectJob.perform_now(jira_import.id, project.id)
      Import::JiraCreateProjectWorkPackagesJob.perform_now(jira_import.id, project.id)
    end
  end

  # Keeps the first job's relations uncommitted until the second job has finished or waits on them.
  # Inspired by modules/backlogs/spec/services/backlogs/work_packages/batch_update_service_concurrency_spec.rb.
  def create_relations_of_both_projects
    second_job = nil
    ActiveRecord::Base.transaction do
      described_class.perform_now(jira_import.id, jira_project.id)
      second_job = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          described_class.perform_now(jira_import.id, other_jira_project.id)
        end
      end
      Timeout.timeout(10) { sleep 0.05 while second_job.alive? && !another_session_waits_on_this_one? }
    end
  ensure
    second_job&.join
  end

  def another_session_waits_on_this_one?
    ActiveRecord::Base.with_connection do |connection|
      connection.select_value(<<~SQL.squish)
        select exists (select from pg_locks where not granted and pg_backend_pid() = any(pg_blocking_pids(pid)))
      SQL
    end
  end

  it "creates the relation once" do
    create_relations_of_both_projects
    expect(Relation.count).to eq(1)
  end

  context "with a second link between the issues, listed in opposite order on each issue" do
    let(:blocks_link_type) { { "name" => "Blocks", "inward" => "is blocked by", "outward" => "blocks" } }
    let(:jira_issue_payload) do
      super().tap do |payload|
        payload["fields"]["issuelinks"] << { "type" => blocks_link_type, "outwardIssue" => { "id" => "10019" } }
      end
    end
    let(:other_jira_issue_links) { [{ "type" => blocks_link_type, "inwardIssue" => { "id" => "10405" } }] + super() }

    it "creates one relation for the pair" do
      create_relations_of_both_projects
      expect(Relation.count).to eq(1)
    end
  end
end
