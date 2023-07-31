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
    let(:attachment) do
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

    let(:user) { create(:admin) }

    def job_status
      JobStatus::Status.last
    end

    before do
      backup
      attachment

      allow(Open3).to receive(:capture3).and_return [nil, "mock restore cmd", db_restore_process_status]

      schema_name = "backup_preview_#{backup.id}"

      expect(job).to receive(:create_new_schema!).with(schema_name)
      expect(Apartment::Migrator).to receive(:migrate).with(schema_name)

      allow(Apartment::Tenant).to receive(:switch) { |schema, _args|
        expect(schema).to eq schema_name
      }
    end

    def perform
      job.perform **arguments.first
    end

    context "with a successfully restored database" do
      before do
        perform
      end

      it "works" do
        expect(job_status.status).to eq "success"
      end
    end
  end

  context "by default" do
    it_behaves_like "it restores the backup"
  end
end
