# frozen_string_literal: true

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

RSpec.describe Storages::Storage, with_flag: { storage_one_drive_integration: true } do
  describe 'scopes' do
    describe '.configured' do
      let!(:configured_nextcloud_storage) do
        create(:nextcloud_storage,
               oauth_application: build(:oauth_application),
               oauth_client: build(:oauth_client))
      end
      let!(:unconfigured_nextcloud_storage) { create(:nextcloud_storage) }
      let!(:configured_one_drive_storage) { create(:one_drive_storage, oauth_client: build(:oauth_client)) }
      let!(:unconfigured_one_drive_storage) { create(:one_drive_storage) }

      it 'returns only storages with complete configuration' do
        configured_storages = described_class.configured
        expect(configured_storages.count).to eq 2
        expect(configured_storages).to contain_exactly(configured_nextcloud_storage, configured_one_drive_storage)
      end
    end
  end
end
