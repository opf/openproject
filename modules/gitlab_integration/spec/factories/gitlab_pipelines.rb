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
  factory :gitlab_pipeline do
    gitlab_merge_request

    sequence(:gitlab_id)
    sequence(:username) { |n| "user_#{n}" }

    name { gitlab_id }
    commit_id { SecureRandom.hex[0..7] }
    details_url { "https://gitlab.com/test_user/test_repo/commit/#{commit_id}" }
    gitlab_html_url { "https://gitlab.com/test_user/test_repo/pipelines/#{gitlab_id}" }
    gitlab_user_avatar_url { "https://www.gravatar.com/avatar/#{gitlab_id}/owner.jpg" }
    status { "pending" }
    started_at { 1.hour.ago }
    completed_at { nil }
    project_id { 1 }

    ci_details do
      build_list(:gitlab_pipeline_ci_detail, 3)
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

  factory :gitlab_pipeline_ci_detail, class: "Hash" do
    skip_create

    initialize_with { attributes }

    stage { %w[test build deploy].sample }
    sequence(:name) { |n| "job_#{n}" }
    status { "success" }
    started_at { 1.hour.ago }
    created_at { started_at }
    finished_at { nil }
    duration { nil }
    queued_duration { nil }
    failure_reason { nil }
    manual { false }
    allow_failure { false }
  end
end
