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
require_relative "shared_base_storage_spec"

RSpec.describe Storages::OneDriveStorage do
  let(:storage) { build(:one_drive_storage) }

  it_behaves_like "base storage"

  describe "#provider_type?" do
    it { expect(storage).to be_a_provider_type_one_drive }
    it { expect(storage).not_to be_a_provider_type_nextcloud }
  end

  describe "#configured?" do
    context "with a complete configuration" do
      let(:storage) { build(:one_drive_storage, :as_not_automatically_managed, oauth_client: build(:oauth_client)) }

      it "returns true" do
        expect(storage.configured?).to be(true)

        aggregate_failures "configuration_checks" do
          expect(storage.configuration_checks)
            .to eq(name_configured: true,
                   storage_oauth_client_configured: true,
                   access_management_configured: true,
                   storage_tenant_drive_configured: true)
        end
      end
    end

    context "without oauth client" do
      let(:storage) { build(:one_drive_storage) }

      it "returns false" do
        expect(storage.configured?).to be(false)

        aggregate_failures "configuration_checks" do
          expect(storage.configuration_checks[:storage_oauth_client_configured]).to be(false)
        end
      end
    end
  end
end
