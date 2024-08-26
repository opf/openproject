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
  factory :github_pull_request do
    github_user

    sequence(:number)
    sequence(:github_id)
    state { "open" }
    github_html_url { "https://github.com/test_user/test_repo/pull/#{number}" }

    labels { [] }
    github_updated_at { Time.current }
    sequence(:title) { |n| "Title of PR #{n}" }
    sequence(:body) { |n| "Body of PR #{n}" }
    sequence(:repository) { |n| "test_user/repo_#{n}" }

    draft { false }
    merged { false }
    merged_by { nil }
    merged_at { nil }

    comments_count { 1 }
    review_comments_count { 2 }
    additions_count { 3 }
    deletions_count { 4 }
    changed_files_count { 5 }

    trait :partial do
      github_user { nil }
      github_id { nil }
      labels { nil }
      github_updated_at { nil }
      title { nil }
      body { nil }
      draft { false }
      merged { false }
      merged_by { nil }
      merged_at { nil }
      comments_count { nil }
      review_comments_count { nil }
      additions_count { nil }
      deletions_count { nil }
      changed_files_count { nil }
    end

    trait :draft do
      draft { true }
    end

    trait :open

    trait :closed_unmerged do
      state { "closed" }
    end

    trait :closed_merged do
      state { "closed" }
      merged { true }
      merged_by { association :github_user }
      merged_at { Time.current }
    end
  end
end
