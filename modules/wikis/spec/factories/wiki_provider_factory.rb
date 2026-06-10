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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

FactoryBot.define do
  factory :wiki_provider, class: "Wikis::Provider" do
    sequence(:name) { |i| "The Wiki Provider ##{i}" }
    universal_identifier { SecureRandom.uuid }
    enabled { true }
  end

  factory :internal_wiki_provider, class: "Wikis::InternalProvider", parent: :wiki_provider do
    name { "internal" }
    universal_identifier { "internal" }
  end

  factory :xwiki_provider, class: "Wikis::XWikiProvider", parent: :wiki_provider do
    url { "https://xwiki.example.com/" }

    transient do
      oauth_client_id { "openproject-#{SecureRandom.hex(8)}" }
      oauth_client_secret { SecureRandom.alphanumeric(20) }
    end

    trait :with_oauth_client do
      after(:create) do |provider, evaluator|
        create :oauth_client, integration: provider,
                              client_id: evaluator.oauth_client_id,
                              client_secret: evaluator.oauth_client_secret
      end
    end

    trait :with_connected_user do
      with_oauth_client

      transient do
        connected_user { association :user }
        connected_user_token { "user-bearer-token" }
      end

      after(:create) do |provider, evaluator|
        create(:oauth_client_token,
               oauth_client: provider.oauth_client,
               user: evaluator.connected_user,
               access_token: evaluator.connected_user_token)
      end
    end

    trait :for_local_connection do
      with_connected_user

      url { "https://xwiki.local" }
      connected_user_token { ENV.fetch("XWIKI_LOCAL_OAUTH_CLIENT_ACCESS_TOKEN", "TOKEN_NOT_CONFIGURED") }
      oauth_client_id { ENV.fetch("XWIKI_LOCAL_OAUTH_CLIENT_ID", "CLIENT_ID_NOT_CONFIGURED") }
      oauth_client_secret { ENV.fetch("XWIKI_LOCAL_OAUTH_CLIENT_SECRET", "CLIENT_SECRET_NOT_CONFIGURED") }
    end

    trait :with_oauth_configured do
      after(:create) do |provider, _evaluator|
        create(:oauth_client, integration: provider)
        create(:oauth_application, integration: provider)
      end
    end
  end
end
