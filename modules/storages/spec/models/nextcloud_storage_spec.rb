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

require_relative '../spec_helper'

RSpec.describe Storages::NextcloudStorage do
  describe '.sync_all_group_folders' do
    subject { described_class.sync_all_group_folders }

    context 'when lock is free' do
      it 'responds with true' do
        expect(subject).to be(true)
      end

      it 'calls GroupFolderPropertiesSyncService for each appropriate storage' do
        storage1 = create(:storage, has_managed_project_folders: true)
        storage2 = create(:storage, has_managed_project_folders: false)
        allow(Storages::GroupFolderPropertiesSyncService).to receive(:new).and_call_original
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Storages::GroupFolderPropertiesSyncService).to receive(:call).and_return(nil)
        # rubocop:enable RSpec/AnyInstance

        expect(subject).to be(true)
        expect(Storages::GroupFolderPropertiesSyncService).to have_received(:new).with(storage1).once
        expect(Storages::GroupFolderPropertiesSyncService).not_to have_received(:new).with(storage2)
      end
    end

    context 'when lock is unfree' do
      it 'responds with false' do
        allow(ApplicationRecord).to receive(:with_advisory_lock).and_return(false)

        expect(subject).to be(false)
        expect(ApplicationRecord).to have_received(:with_advisory_lock).with(
          'sync_all_group_folders',
          timeout_seconds: 0,
          transaction: false
        ).once
      end
    end
  end
end
