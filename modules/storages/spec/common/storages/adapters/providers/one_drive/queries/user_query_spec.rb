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
      module OneDrive
        module Queries
          RSpec.describe UserQuery, :disable_ssrf_filter, :webmock do
            let(:user) { create(:user) }

            let(:storage) do
              create(:one_drive_sandbox_storage, oauth_client_token_user: user)
            end

            let(:user_bound_strategy) do
              Registry.resolve("one_drive.authentication.user_bound").call(user, storage)
            end

            let(:auth_strategy) { user_bound_strategy }

            it "is registered" do
              expect(Registry.resolve("one_drive.queries.user")).to eq(described_class)
            end

            it "responds to .call" do
              expect(described_class).to respond_to(:call)
            end

            it ".call takes required parameters" do
              method = described_class.method(:call)

              expect(method.parameters).to contain_exactly(%i[keyreq auth_strategy], %i[keyreq storage])
            end

            it "responds with user details if request is successful", vcr: "one_drive/user_query_success" do
              command_result = described_class.call(auth_strategy:, storage:)

              expect(command_result).to be_success
              expect(command_result.value!).to eq(id: "a9023fd0-c421-4695-b83c-bb3ba67708d6")
            end

            it "responds with unauthorized if request is unauthorized", vcr: "one_drive/user_query_unauthorized" do
              command_result = described_class.call(auth_strategy:, storage:)

              expect(command_result).to be_failure

              error = command_result.failure
              expect(error.code).to eq(:unauthorized)
            end
          end
        end
      end
    end
  end
end
