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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_module_spec_helper

module Storages
  module Adapters
    RSpec.describe Authentication, :webmock do
      let(:user) { create(:user) }

      let(:noop) { Input::Strategy.build(key: :noop) }
      let(:basic_auth) { Input::Strategy.build(key: :basic_auth) }
      let(:oauth_client_credentials) { Input::Strategy.build(key: :oauth_client_credentials, use_cache: false) }
      let(:oauth_user_token) { Input::Strategy.build(key: :oauth_user_token, user:) }
      let(:sso_user_token) { Input::Strategy.build(key: :sso_user_token, user:) }

      subject(:auth) { described_class }

      it "instantiates the correct strategy based on the data" do
        expect(auth[noop]).to be_a(AuthenticationStrategies::Noop)
        expect(auth[basic_auth]).to be_a(AuthenticationStrategies::BasicAuth)
        expect(auth[oauth_client_credentials]).to be_a(AuthenticationStrategies::OAuthClientCredentials)
        expect(auth[oauth_user_token]).to be_a(AuthenticationStrategies::OAuthUserToken)
        expect(auth[sso_user_token]).to be_a(AuthenticationStrategies::SsoUserToken)
      end

      it "returns an error if an unknown strategy is requested" do
        broken = Input::Strategy.build(key: :unknown)
        expect { auth[broken] }.to raise_error ArgumentError
      end
    end
  end
end
