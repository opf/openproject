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

RSpec.describe Storages::Peripherals::Registry, :webmock do
  using Storages::Peripherals::ServiceResultRefinements

  let(:user) { create(:user) }
  let(:url) { "https://example.com" }
  let(:origin_user_id) { "admin" }
  let(:storage) { build(:nextcloud_storage, :as_automatically_managed, host: url, password: "OpenProjectSecurePassword") }

  subject(:registry) { described_class }

  context "when a key is not registered" do
    it "raises a OperationNotSupported for a non-existent command/query" do
      expect { registry.resolve("nextcloud.commands.destroy_alderaan") }.to raise_error Storages::Errors::OperationNotSupported
      expect { registry.resolve("nextcloud.queries.alderaan") }.to raise_error Storages::Errors::OperationNotSupported
    end

    it "raises a MissingContract for a non-existent contract" do
      expect { registry["warehouse.contracts.storage"] }.to raise_error Storages::Errors::MissingContract
    end

    it "raises a ResolverStandardError in all other cases" do
      expect { registry.resolve("it.is.a.trap") }.to raise_error Storages::Errors::ResolverStandardError
    end
  end

  describe "#delete_folder_command" do
    let(:auth_strategy) { Storages::Peripherals::StorageInteraction::AuthenticationStrategies::BasicAuth.strategy }

    before do
      stub_request(:delete, "https://example.com/remote.php/dav/files/OpenProject/OpenProject/Folder%201")
        .with(headers: { "Authorization" => "Basic T3BlblByb2plY3Q6T3BlblByb2plY3RTZWN1cmVQYXNzd29yZA==" })
        .to_return(status: 204, body: "", headers: {})
    end

    describe "with Nextcloud storage type selected" do
      it "deletes the folder" do
        result = registry.resolve("nextcloud.commands.delete_folder")
                         .call(storage:, auth_strategy:, location: "OpenProject/Folder 1")
        expect(result).to be_success
      end
    end
  end
end
