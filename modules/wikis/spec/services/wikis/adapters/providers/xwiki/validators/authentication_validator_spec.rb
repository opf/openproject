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

RSpec.describe Wikis::Adapters::Providers::XWiki::Validators::AuthenticationValidator do
  subject(:validation_result) { described_class.new(provider).call }

  let(:provider) { create(:xwiki_provider, :with_oauth_configured) }
  let(:query_double) { instance_double(Wikis::Adapters::Providers::XWiki::Queries::User, call: Success()) }

  let(:client_token) { create(:oauth_client_token, user: current_user, oauth_client: provider.oauth_client) }

  current_user { create(:user) }

  before do
    query_class_double = class_double(Wikis::Adapters::Providers::XWiki::Queries::User, new: query_double)
    Wikis::Adapters::Registry.stub("xwiki.queries.user", query_class_double)

    client_token
  end

  it "returns a ResultGroup" do
    expect(validation_result).to be_a(HealthReport::ResultGroup)
    expect(validation_result).to be_success
  end

  context "when the user has no token" do
    let(:client_token) { nil }

    it { is_expected.to be_warning }

    it "indicates that the user has no token" do
      expect(validation_result[:existing_token].code).to eq(:xwiki_oauth_token_missing)
    end
  end

  context "when the user-bound request fails" do
    let(:query_double) do
      instance_double(
        Wikis::Adapters::Providers::XWiki::Queries::User,
        call: Failure(Wikis::Adapters::Results::Error.new(source: self, code: error_code))
      )
    end

    context "with a connection error (network timeout, etc)" do
      let(:error_code) { :connection_error }

      it { is_expected.to be_failure }

      it "indicates that a connection error occured" do
        expect(validation_result[:user_bound_request].code).to eq(:xwiki_oauth_connection_error)
      end
    end

    context "with an authorization error" do
      let(:error_code) { :unauthorized }

      it { is_expected.to be_failure }

      it "indicates that an authorization error occured" do
        expect(validation_result[:user_bound_request].code).to eq(:xwiki_oauth_unauthorized)
      end
    end

    context "with an unexpected response code" do
      let(:error_code) { :request_failed }

      it { is_expected.to be_failure }

      it "indicates that an unexpected error occured" do
        expect(validation_result[:user_bound_request].code).to eq(:xwiki_oauth_request_error)
      end
    end

    context "with an unexpected error" do
      let(:error_code) { :error }

      it { is_expected.to be_failure }

      it "indicates that an unexpected error occured" do
        expect(validation_result[:user_bound_request].code).to eq(:xwiki_oauth_request_error)
      end
    end
  end
end
