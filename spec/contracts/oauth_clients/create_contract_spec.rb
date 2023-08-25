#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'
require_module_spec_helper
require 'contracts/shared/model_contract_shared_context'

RSpec.describe OAuthClients::CreateContract do
  include_context 'ModelContract shared context'

  let(:current_user) { create(:admin) }
  let(:client_id) { "1234567889" }
  let(:client_secret) { "asdfasdfasdf" }
  let(:integration) { build_stubbed(:storage) }
  let(:oauth_client) do
    build(:oauth_client, client_id:, client_secret:, integration:)
  end

  let(:contract) { described_class.new(oauth_client, current_user) }

  it_behaves_like 'contract is valid for active admins and invalid for regular users'

  describe 'validations' do
    context 'when all attributes are valid' do
      include_examples 'contract is valid'

      context 'with client secret being nil' do
        let(:client_secret) { nil }

        include_examples 'contract is valid'
      end
    end

    context 'when client_id is invalid' do
      context 'as it is too long' do
        let(:client_id) { 'X' * 257 }

        include_examples 'contract is invalid', client_id: :too_long
      end

      context 'as it is empty' do
        let(:client_id) { '' }

        include_examples 'contract is invalid', client_id: :blank
      end

      context 'as it is nil' do
        let(:client_id) { nil }

        include_examples 'contract is invalid', client_id: :blank
      end
    end

    context 'when client_secret is invalid' do
      context 'as it is too long' do
        let(:client_secret) { 'X' * 257 }

        include_examples 'contract is invalid', client_secret: :too_long
      end

      context 'as it is empty' do
        let(:client_secret) { '' }

        include_examples 'contract is invalid', client_secret: :too_short
      end
    end

    context 'with integration (polymorphic attribute) linked' do
      let(:integration) { create(:storage) }

      include_examples 'contract is valid'
    end

    context 'without integration (polymorphic attribute)' do
      let(:integration) { nil }

      include_examples 'contract is invalid', { integration_id: :blank, integration_type: :blank }
    end
  end
end
