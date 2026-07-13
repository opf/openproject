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

RSpec.describe Storages::Adapters::Providers::Sharepoint::Validators::AuthenticationValidator, :disable_ssrf_filter, :webmock do
  subject(:validator) { described_class.new(storage) }

  context "when using OAuth2" do
    let(:user) { create(:user) }
    let(:storage) { create(:sharepoint_storage, :sandbox, oauth_client_token_user: user) }
    let(:error) { Storages::Adapters::Results::Error.new(code: :unauthorized, source: self) }

    before { User.current = user }

    it "has the correct key" do
      expect(described_class.key).to eq(:authentication)
    end

    it "passes when the user has a token and the request works", vcr: "sharepoint/user_query_success" do
      expect(validator.call).to be_success
    end

    it "returns a warning when there's no token for the current user" do
      User.current = create(:user)
      result = validator.call

      expect(result[:existing_token]).to be_a_warning
      expect(result[:existing_token].code).to eq(:sp_oauth_token_missing)
      expect(result[:user_bound_request]).to be_skipped
    end

    it "returns a failure if the remote call failed" do
      Storages::Adapters::Registry.stub("sharepoint.queries.user", ->(_) { Failure(error) })

      result = validator.call
      expect(result[:user_bound_request]).to be_a_failure
      expect(result[:user_bound_request].code).to eq(:sp_oauth_request_unauthorized)
    end
  end
end
