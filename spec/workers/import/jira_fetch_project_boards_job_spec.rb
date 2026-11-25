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

RSpec.describe Import::JiraFetchProjectBoardsJob do
  let(:jira) { create(:jira) }
  let(:author) { create(:user) }
  let(:jira_import) { create(:jira_import, jira:, author:) }
  let!(:jira_project) do
    create(:jira_project, jira_import:, origin_id: "10000",
                          payload: { "id" => "10000", "key" => "DEMO", "name" => "Demo" })
  end
  let(:jira_client) { instance_double(Import::JiraClient) }

  def board(id, type = "scrum")
    { "id" => id, "self" => "https://jira.example.com/rest/agile/1.0/board/#{id}", "name" => "Board #{id}", "type" => type }
  end

  # The pages JiraClient#board_pages yields: values, response and the position after the page.
  def pages(*boards_per_page, start_at: 0, total: 3)
    boards_per_page.map do |boards|
      start_at += boards.size
      [boards, { "total" => total, "values" => boards }, start_at]
    end
  end

  def staged_boards
    Import::JiraBoard.where(jira_import:).order(:origin_id)
  end

  before { allow(Import::JiraClient).to receive(:new).and_return(jira_client) }

  describe "#perform" do
    subject(:perform) { described_class.perform_now(jira_import.id, jira_project.id) }

    it "stages every board of every page" do
      allow(jira_client).to receive(:board_pages).with(project_id_or_key: "10000", start_at: 0)
        .and_return(pages([board(1), board(653)], [board(654, "kanban")]).each)

      perform

      expect(staged_boards.pluck(:origin_id, Arel.sql("payload ->> 'type'")))
        .to eq([%w[1 scrum], %w[653 scrum], %w[654 kanban]])
    end

    it "stages a board shared with an already fetched project only once" do
      create(:jira_board, jira_import:, origin_id: "653")
      allow(jira_client).to receive(:board_pages).and_return(pages([board(1), board(653)]).each)

      perform

      expect(staged_boards.pluck(:origin_id)).to eq(%w[1 653])
    end

    it "stages nothing for a project without boards" do
      allow(jira_client).to receive(:board_pages).and_return([].each)

      expect { perform }.not_to change(Import::JiraBoard, :count)
    end

    it "finishes without boards when the Jira Agile API is unavailable" do
      allow(jira_client).to receive(:board_pages)
        .and_raise(Import::JiraClient::UnsupportedEndpointError, "no endpoint (status 403)")

      expect { perform }.not_to raise_error
      expect(staged_boards).to be_empty
    end

    it "skips a project Jira no longer finds" do
      error = Import::JiraClient::ApiError.new("No project could be found", status: 400, response_body: "", response_headers: {})
      allow(jira_client).to receive(:board_pages).and_raise(error)

      expect { perform }.not_to raise_error
      expect(staged_boards).to be_empty
    end

    it "raises any other Jira error" do
      error = Import::JiraClient::ApiError.new("boom", status: 500, response_body: "", response_headers: {})
      allow(jira_client).to receive(:board_pages).and_raise(error)

      expect { perform }.to raise_error(error)
    end

    it "retries a page whose processing was cut short" do
      allow(jira_client).to receive(:board_pages).with(project_id_or_key: "10000", start_at: 0)
        .and_return(pages([board(1), board(653)], [board(654, "kanban")]).each)
      allow(jira_client).to receive(:board_pages).with(project_id_or_key: "10000", start_at: 2)
        .and_return(pages([board(654, "kanban")], start_at: 2).each)
      upserts = 0
      allow(Import::JiraBoard).to receive(:upsert_all).and_wrap_original do |original, *args, **kwargs|
        upserts += 1
        raise "killed" if upserts == 2

        original.call(*args, **kwargs)
      end

      expect { perform }.to raise_error("killed")
      expect(jira_import.get_job_cursor(described_class.new(jira_import.id, jira_project.id))).to include("start_at" => 2)

      described_class.perform_now(jira_import.id, jira_project.id)

      expect(staged_boards.pluck(:origin_id)).to eq(%w[1 653 654])
    end

    it "resumes after the boards fetched before an interruption" do
      job = described_class.new(jira_import.id, jira_project.id)
      jira_import.set_job_cursor(job, { "start_at" => 2, "total" => 3 })
      allow(jira_client).to receive(:board_pages).and_return(pages([board(654, "kanban")], start_at: 2).each)

      perform

      expect(jira_client).to have_received(:board_pages).once
      expect(jira_client).to have_received(:board_pages).with(project_id_or_key: "10000", start_at: 2)
    end
  end

  describe "#progress" do
    subject(:job) { described_class.new(jira_import.id, jira_project.id) }

    it "returns zeros before the first page" do
      expect(job.progress).to eq({ current: 0, total: 0, percentage: 0 })
    end

    it "reports the boards fetched so far" do
      jira_import.set_job_cursor(job, { "start_at" => 2, "total" => 3 })

      expect(job.progress).to eq({ current: 2, total: 3, percentage: 66.67 })
    end
  end
end
