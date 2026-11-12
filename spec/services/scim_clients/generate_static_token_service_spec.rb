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

RSpec.describe ScimClients::GenerateStaticTokenService do
  subject(:service_result) { described_class.new(scim_client).call }

  let(:scim_client) { create(:scim_client, :oauth2_token) }

  it "returns a valid token", :aggregate_failures, :freeze_time do
    expect(service_result).to be_success

    expect(service_result.result.expires_at).to eq(1.year.from_now)
    expect(service_result.result.includes_scope?("scim_v2")).to be_truthy # rubocop:disable RSpec/PredicateMatcher
  end

  it "generates a token" do
    expect { subject }.to change(Doorkeeper::AccessToken, :count).by(1)
  end

  context "when the SCIM client is authenticating through client credentials" do
    let(:scim_client) { create(:scim_client, :oauth2_client) }

    it { is_expected.to be_failure }

    it "does not generate a token" do
      expect { subject }.not_to change(Doorkeeper::AccessToken, :count)
    end
  end

  context "when the SCIM client is authenticating through IDP tokens" do
    let(:scim_client) { create(:scim_client) }

    it { is_expected.to be_failure }

    it "does not generate a token" do
      expect { subject }.not_to change(Doorkeeper::AccessToken, :count)
    end
  end
end
