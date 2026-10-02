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
  factory :repository_merge_request, class: "Repositories::MergeRequest" do
    provider factory: :repository_provider
    repository_user { association :repository_user, provider: }

    sequence(:display_id, &:to_s)
    sequence(:external_id) { |i| (100 + i).to_s } # ensure it doesn't accidentially align with display_id
    state { "opened" }
    web_url { "https://gitlab.com/#{project_name}/-/merge_requests/#{display_id}" }

    labels { [] }
    external_updated_at { Time.current }
    sequence(:title) { |n| "Title of PR #{n}" }
    sequence(:description) { |n| "Description of PR #{n}" }
    sequence(:project_name) { |n| "test_user/repo_#{n}" }

    trait :open

    trait :closed_unmerged do
      state { "closed" }
    end

    trait :closed_merged do
      state { "merged" }
    end
  end
end
