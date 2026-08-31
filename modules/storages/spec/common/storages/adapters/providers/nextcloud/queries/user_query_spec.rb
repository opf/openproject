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

module Storages
  module Adapters
    module Providers
      module Nextcloud
        module Queries
          RSpec.describe UserQuery, :disable_ssrf_filter, :webmock do
            let(:user) { create(:user) }
            let(:storage) do
              create(:nextcloud_storage_with_local_connection, :as_automatically_managed,
                     username: "vcr", oauth_client_token_user: user)
            end

            let(:userless_strategy) { Registry["nextcloud.authentication.userless"].call }
            let(:user_bound_strategy) { Registry["nextcloud.authentication.user_bound"].call(user, storage) }

            it "is registered" do
              expect(Registry.resolve("#{storage}.queries.user")).to eq(described_class)
            end

            it "responds to #call with correct parameters" do
              expect(described_class).to respond_to(:call)

              method = described_class.method(:call)
              expect(method.parameters).to contain_exactly(%i[keyreq storage],
                                                           %i[keyreq auth_strategy])
            end

            it "responds with failure with invalid token", vcr: "nextcloud/user_query_unauthorized" do
              result = described_class.call(storage:, auth_strategy: userless_strategy)

              expect(result).to be_failure
              expect(result.failure.code).to eq(:unauthorized)
            end

            it "responds with success with valid token", vcr: "nextcloud/user_query_success" do
              result = described_class.call(storage:, auth_strategy: user_bound_strategy)

              expect(result).to be_success
              expect(result.value!).to eq(id: "admin")
            end
          end
        end
      end
    end
  end
end
