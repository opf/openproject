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
  factory :tm_assistant_provider, class: "TestManagement::AssistantProvider" do
    sequence(:name) { |n| "Provider #{n}" }
    preset { "custom" }
    base_url { "https://llm.example.com/v1" }
    model { "test-model" }
    user_models { [] }
    is_default { false }

    transient do
      api_key { "sk-factory-secret" }
    end

    after(:build) do |provider, evaluator|
      merged, errors = TestManagement::Assistant::ProviderConfig.apply(
        {}, "assistant_provider" => provider.preset, "assistant_base_url" => provider.base_url.to_s,
            "assistant_model" => provider.model.to_s, "assistant_api_key" => evaluator.api_key.to_s,
            "assistant_auth_style" => provider.auth_style.presence || (provider.preset == "custom" ? "bearer" : nil)
      )
      raise ArgumentError, errors.join(" ") if errors.any?

      provider.assign_settings(merged)
    end

    trait :default do
      is_default { true }
    end
  end
end
