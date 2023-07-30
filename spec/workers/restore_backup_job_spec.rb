#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'

RSpec.describe RestoreBackupJob, type: :model do
  shared_examples "it restores the backup" do |opts = {}|
    let(:job) { RestoreBackupJob.new }

    let(:backup) { create(:backup) }
    let(:status) { :in_queue }
    let(:job_id) { 42 }

    let(:job_status) do
      create(
        :delayed_job_status,
        user:,
        reference: backup,
        status: JobStatus::Status.statuses[status],
        job_id:
      )
    end

    let(:db_restore_process_status) do
      success = db_restore_success

      Object.new.tap do |o|
        o.define_singleton_method(:success?) { success }
      end
    end

    let(:db_restore_success) { false }

    let(:arguments) { [{ backup:, user:, **opts.except(:remote_storage) }] }

    let(:user) { create(:admin) }

    before do
      backup

      allow(job).to receive(:arguments).and_return arguments
      allow(job).to receive(:job_id).and_return job_id

      allow(Open3).to receive(:capture3).and_return [nil, "mock restore cmd", db_restore_process_status]

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

    context "with a successful database dump" do
      let(:db_restore_success) { true }

      let!(:attachment) { create(:attachment) }
      let!(:pending_direct_upload) { create(:pending_direct_upload) }
      let(:stored_backup) { Attachment.where(container_type: "Export").last }
      let(:backup_files) { Zip::File.open(stored_backup.file.path) { |zip| zip.entries.map(&:name) } }

      def backed_up_attachment(attachment)
        "attachment/file/#{attachment.id}/#{attachment.filename}"
      end

      before do
        allow(job).to receive(:remove_paths!)

        perform
      end

      it "stores a new backup as an attachment" do
        expect(stored_backup.filename).to eq "openproject.zip"
      end

      it "includes the database dump in the backup" do
        expect(backup_files).to include "openproject.sql"
      end

      if opts[:include_attachments] == false
        it "does not include attachments in the backup" do
          expect(backup_files).not_to include backed_up_attachment(attachment)
          expect(backup_files).not_to include backed_up_attachment(pending_direct_upload)
        end
      else
        it "includes attachments in the backup" do
          expect(backup_files).to include backed_up_attachment(attachment)
        end

        it "does not include pending direct uploads" do
          expect(backup_files).not_to include backed_up_attachment(pending_direct_upload)
        end

        if opts[:remote_storage] == true
          it "cleans up locally cached files afterwards" do
            expect(job).to have_received(:remove_paths!).with([Pathname(attachment.diskfile.path).parent.to_s])
          end
        else
          it "does not clean up files afterwards as none were cached" do
            expect(job).to have_received(:remove_paths!).with([])
          end
        end
      end
    end
  end

  context "per default" do
    it_behaves_like "it restores the backup"
  end

  context "with preview: true" do
    it_behaves_like "it restores the backup", preview: true
  end
end
