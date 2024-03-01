# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.describe Storages::Peripherals::StorageInteraction::Authentication, :webmock do
  using Storages::Peripherals::ServiceResultRefinements

  let(:user) { create(:user) }

  context 'with a Nextcloud storage' do
    let(:storage) do
      create(:nextcloud_storage_with_local_connection, :as_not_automatically_managed, oauth_client_token_user: user)
    end
    let(:folder) { Storages::Peripherals::ParentFolder.new('/') }

    subject do
      Storages::Peripherals::StorageInteraction::Nextcloud::FilesQuery.new(storage)
    end

    context 'with basic auth strategy' do
      let(:auth_strategy) { Storages::Peripherals::StorageInteraction::AuthenticationStrategies::BasicAuth.strategy }

      subject do
        Storages::Peripherals::StorageInteraction::Nextcloud::GroupUsersQuery.new(storage)
      end

      context 'with empty username and password' do
        it 'must return error' do
          result = subject.call(auth_strategy:, group: storage.group)
          expect(result).to be_failure
          expect(result.error_source)
            .to be_a(Storages::Peripherals::StorageInteraction::AuthenticationStrategies::BasicAuth)

          result.match(
            on_failure: ->(error) { expect(error.code).to eq(:error) },
            on_success: ->(file_infos) { fail "Expected failure, got #{file_infos}" }
          )
        end
      end

      context 'with invalid username and password', vcr: 'auth/nextcloud/storage_query_basic_auth_password_invalid' do
        before do
          storage.password = 'IAmInvalid'
        end

        it 'must return unauthorized' do
          result = subject.call(auth_strategy:, group: storage.group)
          expect(result).to be_failure
          expect(result.error_source)
            .to be_a(Storages::Peripherals::StorageInteraction::Nextcloud::GroupUsersQuery)

          result.match(
            on_failure: ->(error) { expect(error.code).to eq(:unauthorized) },
            on_success: ->(file_infos) { fail "Expected failure, got #{file_infos}" }
          )
        end
      end
    end

    context 'with user token strategy' do
      let(:auth_strategy) do
        Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken.strategy.with_user(user)
      end

      context 'with not existent oauth token' do
        let(:user_without_token) { create(:user) }
        let(:auth_strategy) do
          Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken
            .strategy
            .with_user(user_without_token)
        end

        it 'must return unauthorized' do
          result = subject.call(auth_strategy:, folder:)
          expect(result).to be_failure
          expect(result.error_source)
            .to be_a(Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken)

          result.match(
            on_failure: ->(error) { expect(error.code).to eq(:unauthorized) },
            on_success: ->(file_infos) { fail "Expected failure, got #{file_infos}" }
          )
        end
      end

      context 'with invalid oauth refresh token', vcr: 'auth/nextcloud/storage_query_user_token_refresh_token_invalid' do
        it 'must return unauthorized' do
          result = subject.call(auth_strategy:, folder:)
          expect(result).to be_failure
          expect(result.error_source)
            .to be_a(Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken)

          result.match(
            on_failure: ->(error) { expect(error.code).to eq(:unauthorized) },
            on_success: ->(file_infos) { fail "Expected failure, got #{file_infos}" }
          )
        end
      end

      context 'with invalid oauth access token', vcr: 'auth/nextcloud/storage_query_user_token_access_token_invalid' do
        it 'must refresh token and return success' do
          result = subject.call(auth_strategy:, folder:)
          expect(result).to be_success

          result.match(
            on_failure: ->(error) { fail "Expected success, got #{error}" },
            on_success: ->(file_infos) { expect(file_infos).to be_a(Storages::StorageFiles) }
          )
        end
      end
    end
  end

  context 'with a OneDrive/SharePoint storage' do
    let(:storage) { create(:sharepoint_dev_drive_storage, oauth_client_token_user: user) }
    let(:folder) { Storages::Peripherals::ParentFolder.new('/') }

    subject do
      Storages::Peripherals::StorageInteraction::OneDrive::FilesQuery.new(storage)
    end

    context 'with client credentials strategy' do
      let(:auth_strategy) do
        Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthClientCredentials.strategy
      end

      context 'with invalid oauth credentials', vcr: 'auth/one_drive/storage_query_client_credentials_invalid' do
        it 'must return unauthorized' do
          result = subject.call(auth_strategy:, folder:)
          expect(result).to be_failure
          expect(result.error_source)
            .to be_a(Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthClientCredentials)

          result.match(
            on_failure: ->(error) { expect(error.code).to eq(:unauthorized) },
            on_success: ->(file_infos) { fail "Expected failure, got #{file_infos}" }
          )
        end
      end
    end

    context 'with user token strategy' do
      let(:auth_strategy) do
        Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken.strategy.with_user(user)
      end

      context 'with not existent oauth token' do
        let(:user_without_token) { create(:user) }
        let(:auth_strategy) do
          Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken
            .strategy
            .with_user(user_without_token)
        end

        it 'must return unauthorized' do
          result = subject.call(auth_strategy:, folder:)
          expect(result).to be_failure
          expect(result.error_source)
            .to be_a(Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken)

          result.match(
            on_failure: ->(error) { expect(error.code).to eq(:unauthorized) },
            on_success: ->(file_infos) { fail "Expected failure, got #{file_infos}" }
          )
        end
      end

      context 'with invalid oauth refresh token', vcr: 'auth/one_drive/storage_query_user_token_refresh_token_invalid' do
        it 'must return unauthorized' do
          result = subject.call(auth_strategy:, folder:)
          expect(result).to be_failure
          expect(result.error_source)
            .to be_a(Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken)

          result.match(
            on_failure: ->(error) { expect(error.code).to eq(:unauthorized) },
            on_success: ->(file_infos) { fail "Expected failure, got #{file_infos}" }
          )
        end
      end

      context 'with invalid oauth access token', vcr: 'auth/one_drive/storage_query_user_token_access_token_invalid' do
        it 'must return unauthorized' do
          result = subject.call(auth_strategy:, folder:)
          expect(result).to be_failure
          expect(result.error_source)
            .to be_a(Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken)

          result.match(
            on_failure: ->(error) { expect(error.code).to eq(:unauthorized) },
            on_success: ->(file_infos) { fail "Expected failure, got #{file_infos}" }
          )
        end
      end
    end
  end
end
