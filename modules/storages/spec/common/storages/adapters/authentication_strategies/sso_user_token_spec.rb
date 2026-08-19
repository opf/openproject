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
    module AuthenticationStrategies
      RSpec.describe SsoUserToken do
        let(:storage) { create(:nextcloud_storage) }

        subject(:strategy) { described_class.new(create(:user)) }

        before do
          service = instance_double(OpenIDConnect::UserTokens::FetchService)
          allow(OpenIDConnect::UserTokens::FetchService).to receive(:new).and_return(service)
          allow(service).to receive(:access_token_for).with(audience: storage.audience).and_return(access_token_result)
        end

        context "if access token can be fetched successfully" do
          let(:token) { "my_access_token" }
          let(:access_token_result) { Success(token) }

          it "must yield with access token" do
            was_yielded = false

            strategy.call(storage:) do |http|
              was_yielded = true
              expect(http.instance_variable_get(:@options).headers["authorization"]).to eq("Bearer #{token}")
            end

            expect(was_yielded).to be_truthy
          end
        end

        context "if fetching access token fails" do
          let(:error) { Results::Error.new(code: :error, source: self) }
          let(:access_token_result) { Failure(error) }

          it "must not yield and return failure" do
            was_yielded = false
            result = strategy.call(storage:) { was_yielded = true }

            expect(was_yielded).to be_falsy
            expect(result).to be_failure

            failure = result.failure
            expect(failure.code).to eq(:unauthorized)
            expect(failure).to be_a(Results::Error)
          end
        end
      end
    end
  end
end
