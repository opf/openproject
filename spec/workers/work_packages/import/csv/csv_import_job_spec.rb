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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe WorkPackages::Import::CSV::CsvImportJob do
  shared_let(:type) { create(:type_task, name: "Task") }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:status) { create(:default_status, name: "New") }
  shared_let(:priority) { create(:default_priority, name: "Normal") }
  shared_let(:role) { create(:project_role, permissions: %i[view_work_packages add_work_packages]) }
  shared_let(:user) { create(:user, member_with_roles: { project => role }) }

  let(:content) { "Subject,Type\nWrite the docs,Task\nFix the bug,Task\n" }
  let(:attachment) { import_file(content) }
  let(:dry_run) { true }

  def import_file(body)
    file = Tempfile.new(%w[import .csv])
    file.write(body)
    file.rewind

    create(:attachment, container: WorkPackages::Import::CSV::Upload.create!, author: user, file:)
  end

  def run
    described_class.perform_now(user:, project:, attachment_id: attachment.id, dry_run:)
  end

  def payload
    JobStatus::Status.sole.payload
  end

  describe "a file that checks out" do
    it "reports the checked outcome with the counts" do
      run

      expect(payload).to include("outcome" => "checked",
                                 "row_count" => 2,
                                 "created_count" => 2,
                                 "dry_run" => true,
                                 "problems" => [])
      expect(payload["counts"]).to include("type" => { "Task" => 2 })
    end

    it "names the project, the file and the attachment so the page can commit it" do
      run

      expect(payload).to include("project_id" => project.id,
                                 "filename" => attachment.filename,
                                 "attachment_id" => attachment.id)
    end

    it "writes a successful status" do
      run

      expect(JobStatus::Status.sole.status).to eq("success")
    end

    it "keeps the file, because the commit reuses it" do
      run

      expect(Attachment.exists?(attachment.id)).to be(true)
    end

    it "persists nothing" do
      expect { run }.not_to change(WorkPackage, :count)
    end
  end

  describe "a file that is imported" do
    let(:dry_run) { false }

    it "creates the work packages and reports the imported outcome" do
      expect { run }.to change(WorkPackage, :count).by(2)

      expect(payload).to include("outcome" => "imported", "created_count" => 2)
      expect(JobStatus::Status.sole.status).to eq("success")
    end

    it "deletes the file and its container, which have no further use" do
      run

      expect(Attachment.exists?(attachment.id)).to be(false)
      expect(WorkPackages::Import::CSV::Upload.count).to eq(0)
    end
  end

  describe "a file whose rows are rejected" do
    let(:content) { "Subject,Type\nWrite the docs,Task\n,Task\n" }
    let(:dry_run) { false }

    it "reports the problems and rolls everything back" do
      expect { run }.not_to change(WorkPackage, :count)

      expect(payload).to include("outcome" => "rows_rejected")
      expect(payload["problems"].sole)
        .to include("row" => 3, "attribute" => "subject", "message" => "can't be blank.")
      expect(JobStatus::Status.sole.status).to eq("failure")
    end

    it "deletes the file, since a corrected one has to be uploaded" do
      run

      expect(Attachment.exists?(attachment.id)).to be(false)
    end
  end

  describe "a file the parser rejects" do
    let(:content) { "Subject,Zustaendig\nWrite the docs,someone\n" }

    it "reports the column problems rather than row problems" do
      run

      expect(payload).to include("outcome" => "file_rejected")
      expect(payload["column_problems"].sole)
        .to include("column" => "B", "header" => "Zustaendig")
      expect(JobStatus::Status.sole.status).to eq("failure")
    end
  end

  describe "a file that is not CSV at all" do
    let(:content) { %(Subject,Type\n"unclosed,Task\n) }

    it "names the line the parser choked on" do
      run

      expect(payload).to include("outcome" => "file_rejected")
      expect(payload["column_problems"].sole["message"]).to include("could not be read as CSV")
    end
  end

  describe "a file the sweeper removed before the job started" do
    it "reports it as gone rather than raising" do
      attachment_id = attachment.id
      attachment.destroy

      described_class.perform_now(user:, project:, attachment_id:, dry_run:)

      expect(payload).to include("outcome" => "file_rejected", "attachment_id" => nil)
      expect(payload["column_problems"].sole["message"]).to include("no longer available")
    end
  end

  describe "an attachment moved out of its import container" do
    let(:dry_run) { false }

    def move(attachment)
      attachment.update_columns(container_id: create(:work_package, project:).id,
                                container_type: "WorkPackage")
    end

    it "is not read when the move happened before the job started" do
      move(attachment)

      run

      expect(payload).to include("outcome" => "file_rejected")
      expect(payload["column_problems"].sole["message"]).to include("no longer available")
    end

    it "survives a move that happened before the job started" do
      move(attachment)

      run

      expect(Attachment.exists?(attachment.id)).to be(true)
    end

    it "survives a move that happened while the job was running" do
      allow(WorkPackages::Import::CSV::ImportService).to receive(:new).and_wrap_original do |original, **args|
        move(attachment)
        original.call(**args)
      end

      run

      expect(Attachment.exists?(attachment.id)).to be(true)
    end
  end

  describe "a run that raises" do
    before do
      allow(WorkPackages::Import::CSV::Parser).to receive(:call).and_raise("boom")
    end

    it "still deletes the file" do
      expect { run }.to raise_error("boom")

      expect(Attachment.exists?(attachment.id)).to be(false)
    end
  end

  describe "the view the run saved" do
    let(:dry_run) { false }

    it "is named in the payload, so the report can link to it" do
      run

      expect(Query.find(payload["query_id"]))
        .to have_attributes(user:, project:, public: false)
    end

    it "is absent for a check, whose work packages were rolled back" do
      described_class.perform_now(user:, project:, attachment_id: attachment.id, dry_run: true)

      expect(payload["query_id"]).to be_nil
    end
  end

  describe "the status written before the job runs" do
    it "names the project, the file and the mode, so the page can show a queued run" do
      described_class.perform_later(user:, project:, attachment_id: attachment.id, dry_run: true)

      expect(JobStatus::Status.sole.payload)
        .to include("project_id" => project.id,
                    "filename" => attachment.filename,
                    "dry_run" => true)
    end
  end

  describe "#title" do
    it "says what the run is doing before the job has any of its own state" do
      expect(described_class.new(user:, project:, attachment_id: attachment.id, dry_run: true).title)
        .to eq("Checking the file")
      expect(described_class.new(user:, project:, attachment_id: attachment.id, dry_run: false).title)
        .to eq("Importing the file")
    end
  end
end
