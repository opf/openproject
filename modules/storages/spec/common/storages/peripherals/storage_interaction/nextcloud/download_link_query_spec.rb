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

RSpec.describe Storages::Peripherals::StorageInteraction::Nextcloud::DownloadLinkQuery, :webmock do
  using Storages::Peripherals::ServiceResultRefinements

  let(:user) { create(:user) }
  let(:storage) do
    create(:nextcloud_storage_with_local_connection, :as_not_automatically_managed, oauth_client_token_user: user)
  end
  let(:auth_strategy) do
    Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken.strategy.with_user(user)
  end

  let(:file_link) { create(:file_link, origin_id: "182") }
  let(:not_existent_file_link) { create(:file_link, origin_id: "DeathStarNumberThree") }

  subject { described_class.new(storage) }

  describe "#call" do
    it "responds with correct parameters" do
      expect(described_class).to respond_to(:call)

      method = described_class.method(:call)
      expect(method.parameters).to contain_exactly(%i[keyreq storage], %i[keyreq auth_strategy], %i[keyreq file_link])
    end

    context "without outbound request involved" do
      context "with nil" do
        it "returns an error" do
          result = subject.call(auth_strategy:, file_link: nil)

          expect(result).to be_failure
          expect(result.error_source).to eq(described_class)
          expect(result.result).to eq(:error)
        end
      end
    end

    context "with outbound request successful" do
      it "returns a result with a download url", vcr: "nextcloud/download_link_query_success" do
        download_link = subject.call(auth_strategy:, file_link:)

        expect(download_link).to be_success

        uri = URI(download_link.result)
        expect(uri.host).to eq("nextcloud.local")
        expect(uri.path)
          .to match(/index.php\/apps\/integration_openproject\/direct\/[0-9a-zA-Z]+\/#{file_link.origin_name}/)
      end

      it "returns an error if the file is not found", vcr: "nextcloud/download_link_query_not_found" do
        download_link = subject.call(auth_strategy:, file_link: not_existent_file_link)

        expect(download_link).to be_failure
        expect(download_link.error_source).to eq(described_class)
        expect(download_link.result).to eq(:not_found)
      end
    end

    context "with outbound request returning 200 and an empty body" do
      it "refreshes the token and returns success", vcr: "nextcloud/download_link_query_unauthorized" do
        download_link = subject.call(auth_strategy:, file_link:)

        expect(download_link).to be_success

        uri = URI(download_link.result)
        expect(uri.host).to eq("nextcloud.local")
        expect(uri.path)
          .to match(/index.php\/apps\/integration_openproject\/direct\/[0-9a-zA-Z]+\/#{file_link.origin_name}/)
      end
    end
  end
end
