#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe BackupJob, type: :model do
  shared_examples "it creates a backup" do |opts = {}|
    let(:job) { BackupJob.new }

    let(:previous_backup) { FactoryBot.create :backup }
    let(:backup) { FactoryBot.create :backup }
    let(:status) { :in_queue }
    let(:job_id) { 42 }

    let(:job_status) do
      FactoryBot.create(
        :delayed_job_status,
        user: user,
        reference: backup,
        status: JobStatus::Status.statuses[status],
        job_id: job_id
      )
    end

    let(:db_dump_process_status) do
      success = db_dump_success

      Object.new.tap do |o|
        o.define_singleton_method(:success?) { success }
      end
    end

    let(:db_dump_success) { false }

    let(:arguments) { [{ backup: backup, user: user, **opts }] }

    let(:user) { FactoryBot.create :admin }

    before do
      previous_backup; backup; status # create

      allow(job).to receive(:arguments).and_return arguments
      allow(job).to receive(:job_id).and_return job_id

      expect(Open3).to receive(:capture3).and_return [nil, "Dump failed", db_dump_process_status]

      allow_any_instance_of(BackupJob)
        .to receive(:tmp_file_name).with("openproject", ".sql").and_return("/tmp/openproject.sql")

      allow_any_instance_of(BackupJob)
        .to receive(:tmp_file_name).with("openproject-backup", ".zip").and_return("/tmp/openproject.zip")

      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with("/tmp/openproject.sql").and_return "SOME SQL"
    end

    def perform
      job.perform **arguments.first
    end

    context "with a failed database dump" do
      let(:db_dump_success) { false }

      before { perform }

      it "retains previous backups" do
        expect(Backup.find_by(id: previous_backup.id)).not_to be_nil
      end
    end

    context "with a successful database dump" do
      let(:db_dump_success) { true }

      let!(:attachment) { FactoryBot.create :attachment }
      let(:stored_backup) { Attachment.where(container_type: "Export").last }
      let(:backup_files) { Zip::File.open(stored_backup.file.path) { |zip| zip.entries.map(&:name) } }
      let(:backed_up_attachment) { "attachment/file/#{attachment.id}/#{attachment.filename}" }

      before { perform }

      it "destroys any previous backups" do
        expect(Backup.find_by(id: previous_backup.id)).to be_nil
      end

      it "stores a new backup as an attachment" do
        expect(stored_backup.filename).to eq "openproject.zip"
      end

      it "includes the database dump in the backup" do
        expect(backup_files).to include "openproject.sql"
      end

      if opts[:include_attachments] != false
        it "includes attachments in the backup" do
          expect(backup_files).to include backed_up_attachment
        end
      else
        it "does not include attachments in the backup" do
          expect(backup_files).not_to include backed_up_attachment
        end
      end
    end
  end

  context "per default" do
    it_behaves_like "it creates a backup"
  end

  context "with include_attachments: false" do
    it_behaves_like "it creates a backup", include_attachments: false
  end
end
