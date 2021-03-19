#-- encoding: UTF-8

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
require 'services/base_services/behaves_like_create_service'

describe Backups::CreateService, type: :model do
  it_behaves_like 'BaseServices create service'

  let(:user) { FactoryBot.build_stubbed :admin }
  let(:service) { Backups::CreateService.new user: user }

  context "with right permissions" do
    context "with no further options" do
      it "enqueues a BackupJob which includes attachments" do
        expect { service.call }.to have_enqueued_job(BackupJob).with do |args|
          expect(args["include_attachments"]).to eq true
        end
      end
    end

    context "with include_attachments: false" do
      let(:service) { Backups::CreateService.new user: user, include_attachments: false }

      it "enqueues a BackupJob which does not include attachments" do
        expect(BackupJob)
          .to receive(:perform_later)
          .with(hash_including(include_attachments: false, user: user))

        expect(service.call).to be_success
      end
    end
  end

  context "with missing permission" do
    let(:user) { FactoryBot.build_stubbed :user }

    it "does not enqueue a BackupJob" do
      expect { expect(service.call).to be_failure }.not_to have_enqueued_job(BackupJob)
    end
  end
end
