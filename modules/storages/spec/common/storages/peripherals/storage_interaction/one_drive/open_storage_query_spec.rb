# frozen_string_literal: true

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

RSpec.describe Storages::Peripherals::StorageInteraction::OneDrive::OpenStorageQuery, :webmock do
  using Storages::Peripherals::ServiceResultRefinements

  let(:user) { create(:user) }
  let(:storage) { create(:sharepoint_dev_drive_storage, oauth_client_token_user: user) }

  subject { described_class.new(storage) }

  describe '#call' do
    it 'responds with correct parameters' do
      expect(described_class).to respond_to(:call)

      method = described_class.method(:call)
      expect(method.parameters).to contain_exactly(%i[keyreq storage], %i[keyreq user])
    end

    context 'with outbound requests successful', vcr: 'one_drive/open_storage_query_success' do
      it 'returns the url for opening the storage' do
        call = subject.call(user:)
        expect(call).to be_success
        expect(call.result).to eq('https://finn.sharepoint.com/sites/openprojectfilestoragetests/VCR')
      end
    end

    context 'with not existent oauth token' do
      let(:user_without_token) { create(:user) }

      it 'must return unauthorized when called' do
        result = subject.call(user: user_without_token)
        expect(result).to be_failure
        expect(result.error_source).to be_a(OAuthClients::ConnectionManager)

        result.match(
          on_failure: ->(error) { expect(error.code).to eq(:unauthorized) },
          on_success: ->(file_infos) { fail "Expected failure, got #{file_infos}" }
        )
      end
    end

    context 'with invalid oauth token', vcr: 'one_drive/open_storage_query_invalid_token' do
      before do
        token = build_stubbed(:oauth_client_token, oauth_client: storage.oauth_client)
        allow(Storages::Peripherals::StorageInteraction::OneDrive::Util)
          .to receive(:using_user_token)
                .and_yield(token)
      end

      it 'must return unauthorized' do
        result = subject.call(user:)
        expect(result).to be_failure
        expect(result.error_source).to be_a(described_class)

        result.match(
          on_failure: ->(error) { expect(error.code).to eq(:unauthorized) },
          on_success: ->(file_infos) { fail "Expected failure, got #{file_infos}" }
        )
      end
    end
  end
end
