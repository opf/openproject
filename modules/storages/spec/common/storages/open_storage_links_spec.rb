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

RSpec.describe Storages::OpenStorageLinks do
  describe "static_link" do
    subject { described_class.static_link(storage) }

    context "if storage is of provider type nextcloud" do
      let(:storage) { create(:nextcloud_storage) }

      it "returns the API static link" do
        expect(subject).to eq("/api/v3/storages/#{storage.id}/open")
      end
    end

    context "if storage is of provider type one drive" do
      context "if storage has configured oauth credentials" do
        let(:oauth_client) { create(:oauth_client) }
        let(:storage) { create(:one_drive_storage, oauth_client:) }

        it "returns the 'ensure connections' link" do
          expect(subject).to end_with("/oauth_clients/#{oauth_client.client_id}/ensure_connection?" \
                                      "destination_url=%2Fapi%2Fv3%2Fstorages%2F#{storage.id}%2Fopen&" \
                                      "storage_id=#{storage.id}")
        end
      end

      context "if storage is not fully configured" do
        let(:storage) { create(:one_drive_storage) }

        it "raises an error" do
          expect { subject }.to raise_error(Storages::Errors::ConfigurationError)
        end
      end
    end

    context "if storage is of an unknown provider type" do
      let(:storage) { create(:storage, provider_type: "Storage::Dropbox") }

      it "raises an error" do
        expect { subject }.to raise_error(ArgumentError)
      end
    end
  end

  describe "can_generate_static_link?" do
    subject { described_class.can_generate_static_link?(storage) }

    context "if storage is of provider type nextcloud" do
      let(:storage) { create(:nextcloud_storage) }

      it "returns true" do
        expect(subject).to be_truthy
      end
    end

    context "if storage is of provider type one drive" do
      context "if storage has configured oauth credentials" do
        let(:oauth_client) { create(:oauth_client) }
        let(:storage) { create(:one_drive_storage, oauth_client:) }

        it "returns true" do
          expect(subject).to be_truthy
        end
      end

      context "if storage is not fully configured" do
        let(:storage) { create(:one_drive_storage) }

        it "returns false" do
          expect(subject).to be_falsy
        end
      end
    end

    context "if storage is of an unknown provider type" do
      let(:storage) { create(:storage, provider_type: "Storage::Dropbox") }

      it "returns false" do
        expect(subject).to be_falsy
      end
    end
  end
end
