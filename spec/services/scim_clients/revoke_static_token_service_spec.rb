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

RSpec.describe ScimClients::RevokeStaticTokenService do
  subject(:service_result) { described_class.new(scim_client).call(token) }

  let(:scim_client) { create(:scim_client, :oauth2_token) }
  let(:token) { scim_client.oauth_application.access_tokens.create!(expires_in: 60) }

  it "revokes the token effective immediately", :aggregate_failures, :freeze_time do
    subject
    expect(token.reload).to be_revoked
    expect(token.revoked_at).to be_within(0.1).of(Time.zone.now)
  end

  it { is_expected.to be_success }

  context "when the token is already revoked", :freeze_time do
    let(:token) { scim_client.oauth_application.access_tokens.create!(expires_in: 60, revoked_at: 1.minute.ago) }

    it { is_expected.to be_success }

    it "doesn't set a new revoked_at" do
      subject
      expect(token.reload.revoked_at).to be_within(0.1).of(1.minute.ago)
    end
  end

  context "when the token belongs to a different SCIM client" do
    let(:token) { create(:scim_client, :oauth2_token).oauth_application.access_tokens.create!(expires_in: 60) }

    it { is_expected.to be_failure }

    it "does not revoke the token" do
      subject
      expect(token.reload).not_to be_revoked
    end
  end

  context "when the token belongs to no SCIM client at all" do
    let(:token) { create(:oauth_application).access_tokens.create!(expires_in: 60) }

    it { is_expected.to be_failure }

    it "does not revoke the token" do
      subject
      expect(token.reload).not_to be_revoked
    end
  end
end
