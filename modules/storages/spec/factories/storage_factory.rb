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

FactoryBot.define do
  factory :storage, class: 'Storages::Storage' do
    sequence(:name) { |n| "Storage #{n}" }
    creator factory: :user

    # rubocop:disable FactoryBot/FactoryAssociationWithStrategy
    # For some reason the order of saving breaks STI
    trait :with_oauth_client do
      oauth_client { build(:oauth_client) }
    end
    # rubocop:enable FactoryBot/FactoryAssociationWithStrategy

    factory :one_drive_storage, class: "Storages::OneDriveStorage" do
      host { nil }
    end

    factory :nextcloud_storage, class: 'Storages::NextcloudStorage' do
      sequence(:host) { |n| "https://host#{n}.example.com" }

      trait :as_automatically_managed do
        automatically_managed { true }
        username { 'OpenProject' }
        password { 'Password123' }
      end

      trait :as_not_automatically_managed do
        automatically_managed { false }
      end
    end
  end
end
