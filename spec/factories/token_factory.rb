#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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

require 'securerandom'

FactoryBot.define do
  factory :invitation_token, class: '::Token::Invitation' do
    user
  end

  factory :api_token, class: '::Token::API' do
    user
  end

  factory :rss_token, class: '::Token::RSS' do
    user
  end

  factory :recovery_token, class: '::Token::Recovery' do
    user
  end

  factory :backup_token, class: '::Token::Backup' do
    user

    after(:build) do |token|
      token.created_at = DateTime.now - OpenProject::Configuration.backup_initial_waiting_period
    end

    trait :with_waiting_period do
      transient do
        since { 0.seconds }
      end

      after(:build) do |token, factory|
        token.created_at = DateTime.now - factory.since
      end
    end
  end
end
