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
  factory :semantic_index do
    sequence(:title) { |n| "Semantic index #{n}" }
    description { nil }
    model_id { "bge-m3" }
    embedding_vector_dimensions { 1024 }
    context_token_length { 8192 }

    trait :ready do
      after(:create) do |semantic_index|
        create(:work_package_embedding, semantic_index:)
      end
    end

    trait :indexing do
      after(:create) do |semantic_index|
        batch = GoodJob::Batch.new(semantic_index_id: semantic_index.id).tap(&:save)
        GoodJob::Job.create!(id: SecureRandom.uuid, active_job_id: SecureRandom.uuid, batch_id: batch.id,
                             job_class: Llm::EmbedWorkPackagesJob.name, queue_name: "default",
                             serialized_params: { "arguments" => [semantic_index.id, []] },
                             scheduled_at: 1.hour.from_now)
        semantic_index.update!(indexing_batch_id: batch.id)
      end
    end
  end
end
