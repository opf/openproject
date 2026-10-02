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
require "contracts/shared/model_contract_shared_context"

RSpec.describe OpenIDConnect::Providers::UpdateContract do
  let(:provider) { build_stubbed(:oidc_provider) }
  let(:contract) { described_class.new provider, current_user }

  include_context "ModelContract shared context"

  context "when admin" do
    let(:current_user) { build_stubbed(:admin) }

    it_behaves_like "contract is valid"

    context "when the groups_claim is empty" do
      let(:provider) { build_stubbed(:oidc_provider, groups_claim: "", sync_groups: true) }

      it_behaves_like "contract is invalid", groups_claim: :blank

      context "and when we don't want to synchronize groups" do
        let(:provider) { build_stubbed(:oidc_provider, groups_claim: "", sync_groups: false) }

        it_behaves_like "contract is valid"
      end
    end

    describe "claims" do
      let(:provider) { build_stubbed(:oidc_provider, claims:) }
      let(:claims) { claims_object.to_json }
      let(:claims_object) { { id_token: { my_claim: { essential: true } } } }

      it_behaves_like "contract is valid"

      context "when claims are empty" do
        let(:claims) { "" }

        it_behaves_like "contract is valid"
      end

      context "when a voluntary claim without special needs is requested" do
        let(:claims_object) { { id_token: { my_claim: nil } } }

        it_behaves_like "contract is valid"
      end

      context "when an essential claim with specific values is requested" do
        let(:claims_object) { { id_token: { my_claim: { essential: true, values: %w[a b] } } } }

        it_behaves_like "contract is valid"
      end

      context "when claims are not JSON" do
        let(:claims) { "foobar" }

        it_behaves_like "contract is invalid", claims: :not_json
      end

      context "when claims are not a JSON object" do
        let(:claims_object) { "a JSON string" }

        it_behaves_like "contract is invalid", claims: :not_json_object
      end

      context "when claims contain unsupported root key" do
        let(:claims_object) { { something: { my_claim: nil } } }

        it_behaves_like "contract is invalid", claims: :invalid_claims_location
      end

      context "when claims don't contain object at root key" do
        let(:claims_object) { { id_token: "not allowed to be a string" } }

        it_behaves_like "contract is invalid", claims: :non_object_attribute
      end

      context "when definition of a claim is not a hash" do
        let(:claims_object) { { id_token: { my_claim: "essential" } } }

        it_behaves_like "contract is invalid", claims: :non_object_attribute
      end

      context "when essential attribute of a claim is not a boolean" do
        let(:claims_object) { { id_token: { my_claim: { essential: "false" } } } }

        it_behaves_like "contract is invalid", claims: :invalid_claims_essential
      end

      context "when values attribute of a claim is not an array" do
        let(:claims_object) { { id_token: { my_claim: { values: "foobar" } } } }

        it_behaves_like "contract is invalid", claims: :invalid_claims_values
      end
    end
  end

  context "when non-admin" do
    let(:current_user) { build_stubbed(:user) }

    it_behaves_like "contract is invalid", base: :error_unauthorized
  end
end
