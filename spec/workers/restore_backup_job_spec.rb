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
    let(:job) { described_class.new }

    let(:backup) { create(:backup) }
    let(:backup_attachment) do
      create(
        :attachment,
        file: Rack::Test::UploadedFile.new(
          Rails.root.join('spec', 'fixtures', 'files', 'openproject-backup-test.zip')
        ),
        container: backup
      )
    end

    let(:db_restore_process_status) do
      success = db_restore_success

      Object.new.tap do |o|
        o.define_singleton_method(:success?) { success }
      end
    end

    let(:db_restore_success) { false }
    let(:preview) { false }

    let(:arguments) { [{ backup:, user:, preview:, **opts }] }
    let(:job_id) { 42 }

    let(:user) { create(:admin) }

    let(:schema_name) { "backup_preview_#{backup.id}" }

    # attachments contained in spec/fixtures/files/openproject-backup-test.zip
    let(:attachments) do
      data = [
        [1, "demo_project_teaser.png"],
        [2, "scrum_project_teaser.png"],
        [7, "ff-cactus.jpg"],
        [8, "Pop-Ich-klein_400x400.png"]
      ]

      data.map do |id, file|
        create(:attachment, id:, author: user, filesize: 0, digest: "").tap do |a|
          a.update_column :file, file
        end
      end
    end

    def job_status
      JobStatus::Status.last
    end

    before do
      backup_attachment
      attachments

      allow(job).to receive_messages(arguments:, job_id:)
      allow(job).to receive(:create_new_schema!)

      allow(Apartment::Migrator).to receive(:migrate)
      allow(Apartment::Tenant).to receive(:switch) do |schema, &block|
        if schema == schema_name
          block.call
        else
          raise "Expected schema '#{schema_name}', got '#{schema}'"
        end
      end

      allow(Open3).to receive(:capture3).and_return [nil, "mock restore cmd", db_restore_process_status]

      cleanup_attachments!
    end

    after do
      cleanup_attachments!
    end

    def perform
      job.perform **arguments.first
    end

    def cleanup_attachments!
      path = OpenProject::Configuration.attachments_storage_path.join("attachment/file")

      attachments.each do |a|
        FileUtils.rm_rf path.join(a.id.to_s).to_s
      end
    end

    context "with a successfully restored database" do
      before do
        perform
      end

      it "completes successfully" do
        expect(job_status.status).to eq "success"
      end

      it 'creates a new schema' do
        expect(job).to have_received(:create_new_schema!).with(schema_name)
      end

      it 'restores the database' do
        expect(Open3).to have_received(:capture3) do |_pgenv, cmd|
          expect(cmd).to start_with "psql -f"
          expect(cmd).to end_with ".sql"
        end
      end

      it 'migrates the restored schema' do
        expect(Apartment::Migrator).to have_received(:migrate).with(schema_name)
      end

      it 'imports the attachments from the backup' do
        attachments.each do |a|
          exists = File.exist? a.reload.diskfile.path.to_s

          expect(exists).to be true
          expect(a.filesize).to be > 10000
          expect(a.digest).to be_present
        end
      end
    end
  end

  context "with an existing, valid backup" do
    it_behaves_like "it restores the backup"
  end
end
