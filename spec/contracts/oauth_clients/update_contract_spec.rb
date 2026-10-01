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
require "contracts/shared/model_contract_shared_context"

RSpec.describe OAuthClients::UpdateContract do
  include_context "ModelContract shared context"

  let(:current_user) { create(:admin) }
  let(:client_id) { "1234567889" }
  let(:client_secret) { "asdfasdfasdf" }
  let(:integration) { create(:nextcloud_storage) }
  let(:oauth_client) do
    create(:oauth_client, client_id:, client_secret:, integration:)
  end

  let(:contract) { described_class.new(oauth_client, current_user) }

  it_behaves_like "contract is valid for active admins and invalid for regular users"

  describe "validations" do
    context "when nothing has changed" do
      include_examples "contract is valid"
    end

    context "when client_id changes" do
      before do
        oauth_client.client_id = new_client_id
      end

      context "and it is valid" do
        let(:new_client_id) { "abcdef" }

        include_examples "contract is valid"
      end

      context "and it is too long" do
        let(:new_client_id) { "X" * 257 }

        include_examples "contract is invalid", client_id: :too_long
      end

      context "and it is empty" do
        let(:new_client_id) { "" }

        include_examples "contract is invalid", client_id: :blank
      end

      context "and it is nil" do
        let(:new_client_id) { nil }

        include_examples "contract is invalid", client_id: :blank
      end
    end

    context "when client_secret changes" do
      before do
        oauth_client.client_secret = new_client_secret
      end

      context "and it is valid" do
        let(:new_client_secret) { "highly-secure-client-secret" }

        include_examples "contract is valid"
      end

      context "and it is too long" do
        let(:new_client_secret) { "X" * 257 }

        include_examples "contract is invalid", client_secret: :too_long
      end

      context "and it is empty" do
        let(:new_client_secret) { "" }

        include_examples "contract is invalid", client_secret: :blank
      end

      context "and it is nil" do
        let(:new_client_secret) { nil }

        include_examples "contract is invalid", client_secret: :blank
      end
    end

    context "when changing the integration" do
      let(:new_integration) { create(:nextcloud_storage) }

      before do
        oauth_client.integration = new_integration
      end

      include_examples "contract is invalid", { integration_id: :error_readonly }
    end
  end

  include_examples "contract reuses the model errors"
end
