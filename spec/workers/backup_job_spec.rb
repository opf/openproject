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

    before do
      previous_backup
      backup
      status # create

      allow(job).to receive(:arguments).and_return arguments
      allow(job).to receive(:job_id).and_return job_id

      allow(Open3).to receive(:capture3).and_return [nil, "Dump failed", db_dump_process_status]

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
        allow(job).to receive(:remove_paths!)

        perform
      end

      it "destroys any previous backups" do
        expect(Backup.find_by(id: previous_backup.id)).to be_nil
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
    let(:dummy_path) { "#{LocalFileUploader.cache_dir}/1639754082-3468-0002-0911/file.ext" }

    before do
      FileUtils.mkdir_p Pathname(dummy_path).parent.to_s
      File.open(dummy_path, "w") { |f| f.puts "dummy" }

      allow_any_instance_of(LocalFileUploader).to receive(:cached?).and_return(true)
      allow_any_instance_of(LocalFileUploader)
        .to receive(:local_file)
              .and_return(File.new(dummy_path))
    end

    after do
      FileUtils.rm_rf dummy_path
    end

    it_behaves_like "it creates a backup", remote_storage: true
  end

  context "with include_attachments: false" do
    it_behaves_like "it creates a backup", include_attachments: false
  end
end
