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

# rubocop:disable RSpec/DescribeClass
RSpec.describe "network errors for storage interaction", :webmock do
  using Storages::Peripherals::ServiceResultRefinements

  let(:user) { create(:user) }
  let(:storage) { create(:sharepoint_dev_drive_storage, oauth_client_token_user: user) }
  let(:fields) { Storages::Peripherals::StorageInteraction::OneDrive::FilesQuery::FIELDS }
  let(:request_url) { "https://graph.microsoft.com/v1.0/drives/#{storage.drive_id}/root/children#{fields}" }
  let(:folder) { Storages::Peripherals::ParentFolder.new("/") }
  let(:auth_strategy) do
    Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken.strategy.with_user(user)
  end

  context "if a timeout happens" do
    it "must return an error with wrapped network error response" do
      # Test network error handling specifically with the files query.
      # Other queries and commands should implement the network error handling in the same way.
      stub_request(:get, request_url).to_timeout
      result = Storages::Peripherals::StorageInteraction::OneDrive::FilesQuery.call(storage:, auth_strategy:, folder:)

      expect(result).to be_failure
      expect(result.result).to eq(:error)
      expect(result.error_source).to be(Storages::Peripherals::StorageInteraction::OneDrive::FilesQuery)
      expect(result.error_payload).to be_a(HTTPX::ErrorResponse)
    end
  end
end
# rubocop:enable RSpec/DescribeClass
