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

RSpec.describe Import::JiraFetchProjectVersionsJob do
  let(:jira) { create(:jira) }
  let(:author) { create(:user) }
  let(:jira_import) { create(:jira_import, jira:, author:) }
  let!(:jira_project) do
    create(:jira_project,
           jira_import:,
           origin_id: "10001",
           payload: { "id" => "10001", "key" => "TEST", "name" => "Test Project" })
  end

  subject(:job) { described_class.new(jira_import.id, jira_project.id) }

  describe "#progress" do
    context "when no cursor is set" do
      it "returns zeros" do
        expect(job.progress).to eq({ current: 0, total: 0, percentage: 0 })
      end
    end

    context "when cursor is set" do
      it "calculates progress from cursor data" do
        jira_import.set_job_cursor(job, { "start_at" => 25, "total" => 50 })

        progress = job.progress
        expect(progress[:current]).to eq(25)
        expect(progress[:total]).to eq(50)
        expect(progress[:percentage]).to eq(50.0)
      end

      it "returns 100% when all versions are fetched" do
        jira_import.set_job_cursor(job, { "start_at" => 10, "total" => 10 })

        progress = job.progress
        expect(progress[:current]).to eq(10)
        expect(progress[:total]).to eq(10)
        expect(progress[:percentage]).to eq(100.0)
      end

      it "handles partial progress" do
        jira_import.set_job_cursor(job, { "start_at" => 7, "total" => 21 })

        progress = job.progress
        expect(progress[:current]).to eq(7)
        expect(progress[:total]).to eq(21)
        expect(progress[:percentage]).to eq(33.33)
      end
    end
  end
end
