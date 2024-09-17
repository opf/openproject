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

RSpec.describe Storages::Peripherals::StorageInteraction::Nextcloud::CapabilitiesQuery, :webmock do
  let(:user) { create(:user) }
  let(:storage) do
    create(:nextcloud_storage_with_local_connection, :as_not_automatically_managed, oauth_client_token_user: user)
  end
  let(:auth_strategy) do
    Storages::Peripherals::StorageInteraction::AuthenticationStrategies::Noop.strategy
  end

  it "is registered as queries.capabilities" do
    expect(Storages::Peripherals::Registry.resolve("nextcloud.queries.capabilities")).to eq(described_class)
  end

  it "responds to #call with correct parameters" do
    expect(described_class).to respond_to(:call)

    method = described_class.method(:call)
    expect(method.parameters).to contain_exactly(%i[keyreq storage], %i[keyreq auth_strategy])
  end

  shared_examples_for "a successful Nextcloud capabilities response" do
    it "returns a capabilities object" do
      result = described_class.call(storage:, auth_strategy:)

      expect(result).to be_success

      response = result.result
      expect(response).to be_a(Storages::NextcloudCapabilities)
      expect(response.app_enabled?).to eq(app_enabled?)
      expect(response.app_version).to eq(app_version)
      expect(response.group_folder_enabled?).to eq(group_folder_enabled?)
      expect(response.group_folder_version).to eq(group_folder_version)
    end
  end

  context "if both apps are installed", vcr: "nextcloud/capabilities_success" do
    let(:app_enabled?) { true }
    let(:app_version) { Storages::SemanticVersion.parse("2.6.3") }
    let(:group_folder_enabled?) { true }
    let(:group_folder_version) { Storages::SemanticVersion.parse("16.0.7") }

    it_behaves_like "a successful Nextcloud capabilities response"
  end

  context "if group folder app is installed but disabled", vcr: "nextcloud/capabilities_success_group_folder_disabled" do
    let(:app_enabled?) { true }
    let(:app_version) { Storages::SemanticVersion.parse("2.6.3") }
    let(:group_folder_enabled?) { false }
    let(:group_folder_version) { nil }

    it_behaves_like "a successful Nextcloud capabilities response"
  end

  context "if group folder app is not installed", vcr: "nextcloud/capabilities_success_group_folder_not_installed" do
    let(:app_enabled?) { true }
    let(:app_version) { Storages::SemanticVersion.parse("2.6.3") }
    let(:group_folder_enabled?) { false }
    let(:group_folder_version) { nil }

    it_behaves_like "a successful Nextcloud capabilities response"
  end

  context "if integration app is not installed", vcr: "nextcloud/capabilities_success_app_disabled" do
    let(:app_enabled?) { false }
    let(:app_version) { nil }
    let(:group_folder_enabled?) { false }
    let(:group_folder_version) { nil }

    it_behaves_like "a successful Nextcloud capabilities response"
  end

  context "if response contains invalid version data", vcr: "nextcloud/capabilities_invalid_data" do
    it "returns a failure" do
      result = described_class.call(storage:, auth_strategy:)

      expect(result).to be_failure

      error = result.errors
      expect(error).to be_a(Storages::StorageError)
      expect(error.code).to eq(:error)
      expect(error.log_message).to include("not a valid version string")
    end
  end
end
