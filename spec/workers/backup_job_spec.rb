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

require "spec_helper"

RSpec.describe BackupJob, type: :model do
  shared_examples "it creates a backup" do |opts = {}|
    let(:job) { BackupJob.new }

    let(:previous_backup) { create(:backup) }
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

    let(:db_dump_process_status) do
      success = db_dump_success

      Object.new.tap do |o|
        o.define_singleton_method(:success?) { success }
      end
    end

    let(:db_dump_success) { false }

    let(:arguments) { [{ backup:, user:, **opts.except(:remote_storage) }] }

    let(:user) { create(:admin) }

    let(:openproject_sql) do
      Tempfile.new(["openproject", ".sql"]).tap do |f|
        f.write("SOME SQL")
      end
    end

    before do
      previous_backup
      backup
      status # create

      allow(job).to receive(:arguments).and_return arguments
      allow(job).to receive(:job_id).and_return job_id

      allow(Open3).to receive(:capture3).and_return [nil, "Dump failed", db_dump_process_status]

      allow_any_instance_of(BackupJob)
        .to receive(:tmp_file_name).with("openproject", ".sql").and_return(openproject_sql.path)

      allow_any_instance_of(BackupJob)
        .to receive(:tmp_file_name).with("openproject-backup", ".zip").and_return("/tmp/openproject.zip")

      allow(File).to receive(:read).and_call_original
    end

    def perform
      job.perform **arguments.first
    end

    describe "environment variables" do
      let(:hash_config) do
        ActiveRecord::DatabaseConfigurations::HashConfig.new("test", "primary", config_double)
      end

      before do
        allow(ActiveRecord::Base).to receive(:connection_db_config).and_return(hash_config)
      end

      context "when config has username" do
        let(:config_double) do
          {
            adapter: :postgresql,
            password: "blabla",
            database: "test",
            username: "foobar"
          }
        end

        it "sets PGUSER and other variables" do
          perform

          expect(Open3).to have_received(:capture3) do |*args|
            expect(args[0]).to include("PGUSER" => "foobar", "PGPASSWORD" => "blabla", "PGDATABASE" => "test")
          end
        end
      end

      context "when config has user reference, not username (regression #44251)" do
        let(:config_double) do
          {
            adapter: :postgresql,
            password: "blabla",
            database: "test",
            user: "foobar"
          }
        end

        it "still sets PGUSER and other variables" do
          perform

          expect(Open3).to have_received(:capture3) do |*args|
            expect(args[0]).to include("PGUSER" => "foobar", "PGPASSWORD" => "blabla", "PGDATABASE" => "test")
          end
        end
      end
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

      let!(:attachment) { create(:attachment) }
      let!(:pending_direct_upload) { create(:pending_direct_upload) }
      let(:stored_backup) { Attachment.where(container_type: "Export").last }
      let(:backup_files) { Zip::File.open(stored_backup.file.path) { |zip| zip.entries.map(&:name) } }

      def backed_up_attachment(attachment)
        "attachment/file/#{attachment.id}/#{attachment.filename}"
      end

      before do
        perform
      end

      it "destroys any previous backups" do
        expect(Backup.find_by(id: previous_backup.id)).to be_nil
      end

      it "stores a new backup as an attachment" do
        expect(stored_backup.filename).to eq "openproject.zip"
      end

      it "does not mark the backup as incomplete" do
        expect(stored_backup.filename).not_to include "-incomplete"
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
      end
    end
  end

  context "per default" do
    it_behaves_like "it creates a backup"
  end

  context(
    "with remote storage",
    with_config: {
      attachments_storage: :fog,
      fog: {
        directory: MockCarrierwave.bucket,
        credentials: MockCarrierwave.credentials
      }
    }
  ) do
    let(:dummy_file) { Pathname("#{LocalFileUploader.cache_dir}/1639754082-3468-0002-0911/file.ext") }

    before do
      dummy_file.parent.mkpath
      dummy_file.write("dummy")

      allow_any_instance_of(LocalFileUploader).to receive(:local_file).and_return(File.new(dummy_file))
    end

    after do
      dummy_file.unlink
    end

    it_behaves_like "it creates a backup", remote_storage: true
  end

  context "with include_attachments: false" do
    it_behaves_like "it creates a backup", include_attachments: false
  end

  context "with an unreadable attachment" do
    let(:job) { described_class.new }
    let(:backup) { create(:backup) }
    let(:user) { create(:admin) }
    let(:job_id) { 42 }

    let!(:job_status) do
      create(
        :delayed_job_status,
        user:,
        reference: backup,
        status: JobStatus::Status.statuses[:in_queue],
        job_id:
      )
    end

    let(:openproject_sql) do
      Tempfile.new(["openproject", ".sql"]).tap { |f| f.write("SOME SQL") }
    end

    let!(:readable_attachment) { create(:attachment) }
    let!(:unreadable_attachment) { create(:attachment) }

    let(:stored_backup) { Attachment.where(container_type: "Export").last }
    let(:backup_files) { Zip::File.open(stored_backup.file.path) { |zip| zip.entries.map(&:name) } }
    let(:missing_attachments_txt) do
      Zip::File.open(stored_backup.file.path) { |zip| zip.read("MISSING_ATTACHMENTS.txt") }
    end

    def backed_up_attachment(attachment)
      "attachment/file/#{attachment.id}/#{attachment.filename}"
    end

    before do
      allow(job).to receive_messages(arguments: [{ backup:, user: }], job_id:)

      allow(Open3).to receive(:capture3).and_return [nil, "", instance_double(Process::Status, success?: true)]

      allow(job).to receive(:tmp_file_name).with("openproject", ".sql").and_return(openproject_sql.path)
      allow(job).to receive(:tmp_file_name)
        .with("openproject-backup", ".zip").and_return("/tmp/openproject-unreadable.zip")

      # Attachments are re-queried from the database inside the job, so there is no handle to the
      # specific instances whose uploader needs stubbing.
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(LocalFileUploader).to receive(:readable?) do |uploader|
        uploader.model.id != unreadable_attachment.id
      end
      # rubocop:enable RSpec/AnyInstance

      job.perform(backup:, user:)
    end

    it "includes MISSING_ATTACHMENTS.txt listing the missing attachment" do
      expect(backup_files).to include "MISSING_ATTACHMENTS.txt"
      expect(missing_attachments_txt).to include(unreadable_attachment.id.to_s)
      expect(missing_attachments_txt).to include(unreadable_attachment[:file])
    end

    it "still includes the readable attachment" do
      expect(backup_files).to include backed_up_attachment(readable_attachment)
    end

    it "does not include the unreadable attachment" do
      expect(backup_files).not_to include backed_up_attachment(unreadable_attachment)
    end

    it "names the backup archive with an -incomplete suffix" do
      expect(stored_backup.filename).to eq "openproject-unreadable-incomplete.zip"
    end
  end
end
