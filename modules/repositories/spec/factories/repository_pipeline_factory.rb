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
  factory :repository_pipeline, class: "Repositories::Pipeline" do
    transient do
      merge_request { association :repository_merge_request, provider: }
    end

    provider factory: :repository_provider
    repository_user { association :repository_user, provider: }
    sequence(:external_id, &:to_s)
    sequence(:external_project_id, &:to_s)
    web_url { "https://gitlab.com/test_user/test_repo/-/pipelines/#{external_id}" }
    details_url { "https://gitlab.com/test_user/test_repo/-/pipelines/#{external_id}/builds" }
    status { "pending" }
    started_at { 1.hour.ago }
    completed_at { nil }

    after(:build) do |pipeline, evaluator|
      pipeline.merge_requests = [evaluator.merge_request] if evaluator.merge_request
    end

    trait :complete do
      status { "success" }
      completed_at { 1.minute.ago }
    end

    trait :recent do
      started_at { 1.minute.ago }
    end

    trait :outdated do
      started_at { 1.day.ago }
    end
  end

  factory :repository_pipeline_job, class: "Repositories::PipelineJob" do
    pipeline factory: :repository_pipeline
    sequence(:external_id, &:to_s)
    external_source_id { "gitlab" }
    sequence(:name) { |n| "job_#{n}" }
    stage { "test" }
    status { "success" }
    web_url { "https://gitlab.com/test_user/test_repo/-/jobs/#{external_id}" }
    started_at { 1.hour.ago }
    completed_at { nil }
  end
end
