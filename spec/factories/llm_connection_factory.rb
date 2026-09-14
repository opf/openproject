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
  factory :llm_connection do
    sequence(:identifier) { |n| n == 1 ? LlmConnection::DEFAULT_IDENTIFIER : "connection-#{n}" }
    base_url { "https://example.com/v1" }
    api_key { "sk-test-key" }
    trait :with_models do
      transient do
        default_chat_model_identifier { nil }
        default_embedding_model_identifier { nil }
      end

      catalogue_fetched_at { Time.current }
      last_connected_at { Time.current }

      after(:create) do |connection, evaluator|
        create(:llm_model, llm_connection: connection, external_id: "qwen3.6-27b",
                           raw_metadata: { "owned_by" => "vllm", "max_model_len" => 262_144 })
        create(:llm_model, llm_connection: connection, external_id: "bge-m3",
                           raw_metadata: { "owned_by" => "vllm", "max_model_len" => 8_192 })

        defaults = { default_chat_model: evaluator.default_chat_model_identifier,
                     default_embedding_model: evaluator.default_embedding_model_identifier }
                     .compact
                     .transform_values { |id| connection.models.find_by!(external_id: id) }

        connection.update!(defaults) if defaults.any?
      end
    end
  end
end
