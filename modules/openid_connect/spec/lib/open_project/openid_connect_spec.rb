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

RSpec.describe OpenProject::OpenIDConnect do
  describe ".providers" do
    subject { described_class.providers.map(&:to_h) }

    it { is_expected.to be_empty }

    context "when there is a provider" do
      let!(:provider) { create(:oidc_provider, claims:, acr_values:) }
      let(:claims) do
        {
          id_token: {
            taste: {
              essential: true,
              values: ["sweet", "bitter", "salty"]
            }
          }
        }.to_json
      end
      let(:acr_values) { "silver gold" }

      it "configures basic attributes", :aggregate_failures do
        config = subject.first

        expect(config[:issuer]).to eq(provider.issuer)
        expect(config[:name]).to eq(provider.slug.to_sym)
      end

      it "configures client_options", :aggregate_failures do
        client_options = subject.first.fetch(:client_options)

        expect(client_options[:identifier]).to eq(provider.client_id)
        expect(client_options[:secret]).to eq(provider.client_secret)
        expect(client_options[:redirect_uri]).to eq(provider.callback_url)

        %i[host authorization_endpoint token_endpoint userinfo_endpoint jwks_uri end_session_endpoint].each do |attr|
          expect(client_options[attr]).to eq(provider.public_send(attr))
        end
      end

      it "even has config for claims and acr_values (regression #66217)" do
        config = subject.first

        expect(config[:claims]).to eq(provider.claims)
        expect(config[:acr_values]).to eq(provider.acr_values)
      end

      context "and when the claims are empty" do
        let(:claims) { "" }

        it "configures claims to be an empty JSON object" do
          config = subject.first
          expect(config[:claims]).to eq("{}")
        end
      end
    end
  end
end
