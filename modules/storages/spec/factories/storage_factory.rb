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

FactoryBot.define do
  factory :storage, class: "Storages::Storage" do
    sequence(:name) { |n| "Storage #{n}" }
    creator factory: :user

    trait :with_oauth_client do
      oauth_client
    end

    trait :as_generic do
      provider_type { "Storages::Storage" }
    end

    trait :as_generic do
      provider_type { "Storages::Storage" }
    end

    trait :as_not_automatically_managed do
      automatically_managed { false }
    end

    trait :as_healthy do
      health_status { "healthy" }
      health_reason { nil }
      health_changed_at { Time.now.utc }
      health_checked_at { Time.now.utc }
    end

    trait :as_unhealthy do
      health_status { "unhealthy" }
      health_reason { "error_code | description" }
      health_changed_at { Time.now.utc }
      health_checked_at { Time.now.utc }
    end

    trait :as_unhealthy_long_reason do
      health_status { "unhealthy" }
      health_reason { "unauthorized | Outbound request not authorized | #<Storages::StorageErrorData:0x0000ffff646ac570>" }
      health_changed_at { Time.now.utc }
      health_checked_at { Time.now.utc }
    end

    trait :as_pending do
      health_status { "pending" }
      health_reason { nil }
      health_changed_at { Time.now.utc }
      health_checked_at { Time.now.utc }
    end

    trait :with_health_notifications_enabled do
      health_notifications_enabled { true }
    end

    trait :with_health_notifications_disabled do
      health_notifications_enabled { false }
    end
  end

  factory :nextcloud_storage,
          parent: :storage,
          class: "::Storages::NextcloudStorage" do
    provider_type { Storages::Storage::PROVIDER_TYPE_NEXTCLOUD }
    sequence(:host) { |n| "https://host#{n}.example.com/" }

    trait :as_automatically_managed do
      automatic_management_enabled { true }
      username { "OpenProject" }
      password { "Password123" }
    end
  end

  factory :nextcloud_storage_configured, parent: :nextcloud_storage do
    after(:create) do |storage, _evaluator|
      create(:oauth_client, integration: storage)
      create(:oauth_application, integration: storage)
    end
  end

  factory :nextcloud_storage_with_local_connection,
          parent: :nextcloud_storage,
          traits: [:as_not_automatically_managed] do
    transient do
      oauth_client_token_user { association :user }
      origin_user_id { "admin" }
    end

    name { "Nextcloud Local" }
    host { "https://nextcloud.local/" }

    initialize_with do
      Storages::NextcloudStorage.create_or_find_by(attributes.except(:oauth_client, :oauth_application))
    end

    after(:create) do |storage, evaluator|
      create(:oauth_client,
             client_id: ENV.fetch("NEXTCLOUD_LOCAL_OAUTH_CLIENT_ID", "MISSING_NEXTCLOUD_LOCAL_OAUTH_CLIENT_ID"),
             client_secret: ENV.fetch("NEXTCLOUD_LOCAL_OAUTH_CLIENT_SECRET", "MISSING_NEXTCLOUD_LOCAL_OAUTH_CLIENT_SECRET"),
             integration: storage)

      create(:oauth_application,
             uid: ENV.fetch("NEXTCLOUD_LOCAL_OPENPROJECT_UID", "MISSING_NEXTCLOUD_LOCAL_OPENPROJECT_UID"),
             secret: ENV.fetch("NEXTCLOUD_LOCAL_OPENPROJECT_SECRET", "MISSING_NEXTCLOUD_LOCAL_OPENPROJECT_SECRET"),
             redirect_uri: ENV.fetch("NEXTCLOUD_LOCAL_OPENPROJECT_REDIRECT_URI",
                                     "https://nextcloud.local/index.php/apps/integration_openproject/oauth-redirect"),
             scopes: "api_v3",
             integration: storage)

      create(:oauth_client_token,
             oauth_client: storage.oauth_client,
             user: evaluator.oauth_client_token_user,
             access_token: ENV.fetch("NEXTCLOUD_LOCAL_OAUTH_CLIENT_ACCESS_TOKEN",
                                     "MISSING_NEXTCLOUD_LOCAL_OAUTH_CLIENT_ACCESS_TOKEN"),
             refresh_token: ENV.fetch("NEXTCLOUD_LOCAL_OAUTH_CLIENT_REFRESH_TOKEN",
                                      "MISSING_NEXTCLOUD_LOCAL_OAUTH_CLIENT_REFRESH_TOKEN"),
             token_type: "bearer")

      create(:remote_identity,
             oauth_client: storage.oauth_client,
             user: evaluator.oauth_client_token_user,
             origin_user_id: evaluator.origin_user_id)
    end
  end

  factory :nextcloud_storage_with_complete_configuration,
          parent: :nextcloud_storage,
          traits: [:as_automatically_managed] do
    sequence(:host) { |n| "https://host-complete#{n}.example.com" }

    after(:create) do |storage|
      create(:oauth_client, integration: storage)
      create(:oauth_application, integration: storage)
    end
  end

  factory :one_drive_storage,
          parent: :storage,
          class: "::Storages::OneDriveStorage" do
    host { nil }
    tenant_id { SecureRandom.uuid }
    drive_id { SecureRandom.uuid }
    automatically_managed { false }

    trait :as_automatically_managed do
      automatically_managed { true }
    end
  end

  factory :one_drive_storage_configured, parent: :one_drive_storage do
    after(:create) do |storage, _evaluator|
      create(:oauth_client, integration: storage)
      create(:oauth_application, integration: storage)
    end
  end

  factory :sharepoint_dev_drive_storage,
          parent: :one_drive_storage do
    automatically_managed { false }

    transient do
      oauth_client_token_user { association :user }
    end

    name { "Sharepoint VCR drive" }
    tenant_id { ENV.fetch("ONE_DRIVE_TEST_TENANT_ID", "4d44bf36-9b56-45c0-8807-bbf386dd047f") }
    drive_id { ENV.fetch("ONE_DRIVE_TEST_DRIVE_ID", "b!dmVLG22QlE2PSW0AqVB7UOhZ8n7tjkVGkgqLNnuw2OBb-brzKzZAR4DYT1k9KPXs") }

    after(:create) do |storage, evaluator|
      create(:oauth_client,
             client_id: ENV.fetch("ONE_DRIVE_TEST_OAUTH_CLIENT_ID", "MISSING_ONE_DRIVE_TEST_OAUTH_CLIENT_ID"),
             client_secret: ENV.fetch("ONE_DRIVE_TEST_OAUTH_CLIENT_SECRET",
                                      "MISSING_ONE_DRIVE_TEST_OAUTH_CLIENT_SECRET"),
             integration: storage)

      create(:oauth_client_token,
             oauth_client: storage.oauth_client,
             user: evaluator.oauth_client_token_user,
             access_token: ENV.fetch("ONE_DRIVE_TEST_OAUTH_CLIENT_ACCESS_TOKEN",
                                     "MISSING_ONE_DRIVE_TEST_OAUTH_CLIENT_ACCESS_TOKEN"),
             refresh_token: ENV.fetch("ONE_DRIVE_TEST_OAUTH_CLIENT_REFRESH_TOKEN",
                                      "MISSING_ONE_DRIVE_TEST_OAUTH_CLIENT_REFRESH_TOKEN"),
             token_type: "bearer")
      create(:remote_identity, oauth_client: storage.oauth_client, user: evaluator.oauth_client_token_user,
                               origin_user_id: "33db2c84-275d-46af-afb0-c26eb786b194")
    end
  end
end
