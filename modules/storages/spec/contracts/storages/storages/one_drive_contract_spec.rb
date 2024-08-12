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
require_module_spec_helper

RSpec.describe Storages::Storages::OneDriveContract, :storage_server_helpers, :webmock do
  let(:current_user) { create(:admin) }
  let(:storage) { build(:one_drive_storage) }

  # As the OneDriveContract is selected by the BaseContract to make writable attributes available,
  # the BaseContract needs to be instantiated here.
  subject(:contract) { Storages::Storages::BaseContract.new(storage, current_user) }

  describe "when a host is set" do
    before do
      storage.host = "https://exmaple.com/"
    end

    it "must be invalid" do
      expect(contract).not_to be_valid
    end
  end

  context "with tenant that is no UUID" do
    let(:storage) { build(:one_drive_storage, tenant_id: "123") }

    it "is invalid" do
      expect(contract).not_to be_valid

      expect(contract.errors[:tenant_id]).to eq(["is invalid."])
    end
  end

  context "with blank Drive ID" do
    let(:storage) { build(:one_drive_storage, drive_id: "") }

    it "is invalid" do
      expect(contract).not_to be_valid

      expect(contract.errors[:drive_id]).to eq(["can't be blank.", "is too short (minimum is 17 characters)."])
    end
  end

  context "with short Drive ID" do
    let(:storage) { build(:one_drive_storage, drive_id: "1234567890") }

    it "is invalid" do
      expect(contract).not_to be_valid

      expect(contract.errors[:drive_id]).to eq(["is too short (minimum is 17 characters)."])
    end
  end
end
