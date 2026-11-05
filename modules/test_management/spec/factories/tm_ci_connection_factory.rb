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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

FactoryBot.define do
  factory :tm_ci_connection, class: "TestManagement::CiConnection" do
    project
    sequence(:name) { |n| "Shop #{n}" }
    provider { "github" }
    sequence(:repository) { |n| "my-org/shop-#{n}" }
    ingest_mode { "new_run" }
    active { true }

    trait :new_iteration do
      ingest_mode { "new_iteration" }
      target_run_name { "Smoke" }
    end

    trait :with_token do
      token { "ghp_secret_token_value" }
    end

    trait :github_trigger do
      repository { "my-org/shop" }
      workflow { "e2e.yml" }
      token { "ghp_trigger_secret" }
    end
  end
end
