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
require "services/base_services/behaves_like_create_service"

RSpec.describe Backups::CreateService, type: :model do
  let(:user) { create(:admin) }
  let(:service) { described_class.new user:, backup_token: backup_token.plain_value }
  let(:backup_token) { create(:backup_token, user:) }

  it_behaves_like "BaseServices create service" do
    let(:instance) { service }
    let(:backup_token) { build_stubbed(:backup_token, user:) }
    let(:contract_options) { { backup_token: backup_token.plain_value } }
  end

  context "with right permissions" do
    context "with no further options" do
      it "enqueues a BackupJob which includes attachments" do
        expect { service.call }.to have_enqueued_job(BackupJob).with do |args|
          expect(args["include_attachments"]).to be true
        end
      end
    end

    context "with include_attachments: false" do
      let(:service) do
        described_class.new user:, backup_token: backup_token.plain_value, include_attachments: false
      end

      it "enqueues a BackupJob which does not include attachments" do
        expect(BackupJob)
          .to receive(:perform_later)
          .with(hash_including(include_attachments: false, user:))

        expect(service.call).to be_success
      end
    end
  end

  context "with missing permission" do
    let(:user) { create(:user) }

    it "does not enqueue a BackupJob" do
      expect { expect(service.call).to be_failure }.not_to have_enqueued_job(BackupJob)
    end
  end
end
