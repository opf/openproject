# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
RSpec.describe "network errors for storage interaction" do
  using Storages::Peripherals::ServiceResultRefinements

  let(:user) { create(:user) }
  let(:storage) { create(:sharepoint_dev_drive_storage, oauth_client_token_user: user) }
  let(:request_url) { "https://my.timeout.org/" }
  let(:auth_strategy) do
    Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken.strategy.with_user(user)
  end

  context "if a timeout happens" do
    before do
      request = HTTPX::Request.new(:get, request_url)
      httpx_double = class_double(HTTPX, get: HTTPX::ErrorResponse.new(request, "Timeout happens", {}))
      allow(httpx_double).to receive(:with).and_return(httpx_double)
      allow(OpenProject).to receive(:httpx).and_return(httpx_double)
    end

    it "must return an error with wrapped network error response" do
      result = Storages::Peripherals::StorageInteraction::Authentication[auth_strategy].call(storage:) do |http|
        make_request(http)
      end

      expect(result).to be_failure
      expect(result.result).to eq(:error)
      expect(result.error_payload).to be_a(HTTPX::ErrorResponse)
    end
  end

  private

  def make_request(http)
    handle_response http.get(request_url)
  end

  def handle_response(response)
    case response
    in { status: 200..299 }
      ServiceResult.success(result: "EXPECTED_RESULT")
    in { status: 401 }
      error(:unauthorized)
    in { status: 403 }
      error(:forbidden)
    in { status: 404 }
      error(:not_found)
    else
      error(:error, response)
    end
  end

  def error(code, payload = nil)
    data = Storages::StorageErrorData.new(source: "EXECUTING_QUERY", payload:)
    ServiceResult.failure(result: code, errors: Storages::StorageError.new(code:, data:))
  end
end
# rubocop:enable RSpec/DescribeClass
