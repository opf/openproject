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

FactoryBot.define do
  factory :storage, class: '::Storages::Storage' do
    provider_type { Storages::Storage::PROVIDER_TYPE_NEXTCLOUD }
    sequence(:name) { |n| "Storage #{n}" }
    sequence(:host) { |n| "https://host#{n}.example.com" }
    creator factory: :user

    factory :nextcloud_storage, class: '::Storages::NextcloudStorage' do
      provider_type { Storages::Storage::PROVIDER_TYPE_NEXTCLOUD }

      trait :as_automatically_managed do
        automatically_managed { true }
        username { 'OpenProject' }
        password { 'Password123' }
      end

      trait :as_not_automatically_managed do
        automatically_managed { false }
      end

      factory :nextcloud_storage_with_real_integration, traits: [:as_automatically_managed] do
        transient do
          oauth_client_token_user { association :user }
        end

        name { 'Nextcloud Local' }
        host { 'https://nextcloud.local' }

        initialize_with do
          Storages::NextcloudStorage.create_or_find_by(attributes.except(:oauth_client, :oauth_application))
        end

        after(:create) do |storage, evaluator|
          create(:oauth_client,
                 client_id: ENV.fetch('NEXTCLOUD_LOCAL_OAUTH_CLIENT_ID', nil),
                 client_secret: ENV.fetch('NEXTCLOUD_LOCAL_OAUTH_CLIENT_SECRET', nil),
                 integration: storage)

          create(:oauth_application,
                 uid: ENV.fetch('NEXTCLOUD_LOCAL_OPENPROJECT_UID', 'MISSING_NEXTCLOUD_LOCAL_OPENPROJECT_UID'),
                 secret: ENV.fetch('NEXTCLOUD_LOCAL_OPENPROJECT_SECRET', 'MISSING_NEXTCLOUD_LOCAL_OPENPROJECT_SECRET'),
                 redirect_uri: ENV.fetch('NEXTCLOUD_LOCAL_OPENPROJECT_REDIRECT_URI',
                                         "https://nextcloud.local/index.php/apps/integration_openproject/oauth-redirect"),
                 scopes: 'api_v3',
                 integration: storage)

          create(:oauth_client_token,
                 oauth_client: storage.oauth_client,
                 user: evaluator.oauth_client_token_user,
                 access_token: ENV.fetch('NEXTCLOUD_LOCAL_OAUTH_CLIENT_ACCESS_TOKEN',
                                         'MISSING_NEXTCLOUD_LOCAL_OAUTH_CLIENT_ACCESS_TOKEN'),
                 refresh_token: ENV.fetch('NEXTCLOUD_LOCAL_OAUTH_CLIENT_REFRESH_TOKEN',
                                          'MISSING_NEXTCLOUD_LOCAL_OAUTH_CLIENT_REFRESH_TOKEN'),
                 token_type: 'bearer',
                 origin_user_id: 'admin')
        end
      end
    end
  end
end
