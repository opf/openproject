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
require_relative "shared_contract_examples"

RSpec.describe Storages::Storages::UpdateContract do
  it_behaves_like "nextcloud storage contract" do
    let(:storage) do
      build_stubbed(:nextcloud_storage,
                    creator: storage_creator,
                    host: storage_host,
                    name: storage_name,
                    provider_type: storage_provider_type)
    end
    let(:contract) { described_class.new(storage, current_user) }

    context "when current user is not the initial storage creator" do
      let(:storage_creator) { build_stubbed(:user) }

      include_examples "contract is valid"
    end

    context "when host is unchanged from an already-persisted insecure value" do
      let(:storage_host) { "http://nc.openproject.com" }

      before { storage.clear_changes_information }

      context "when only name changes" do
        before { storage.name = "Renamed storage" }

        include_examples "contract is valid"

        it "does not perform metadata discovery requests" do
          contract.validate

          expect(WebMock).not_to have_requested(:get, "http://nc.openproject.com/ocs/v2.php/cloud/capabilities")
        end
      end

      context "when host is also changed to a new insecure value" do
        before { storage.host = "http://another-unsafe-host.example" }

        include_examples "contract is invalid", host: :url_not_secure_context

        it "does not perform metadata discovery requests" do
          contract.validate

          expect(WebMock).not_to have_requested(:get, "http://another-unsafe-host.example/ocs/v2.php/cloud/capabilities")
        end
      end
    end
  end
end
