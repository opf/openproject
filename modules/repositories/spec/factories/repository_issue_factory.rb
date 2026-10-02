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
  factory :repository_issue do
    provider factory: :repository_provder
    repository_user

    sequence(:display_id)
    sequence(:external_id) { |i| 100 + i } # ensure it doesn't accidentially align with display_id
    state { "opened" }
    web_url { "https://gitlab.com/#{project_name}/issues/#{display_id}" }

    labels { [] }
    gitlab_updated_at { Time.current }
    sequence(:title) { |n| "Title of ISSUE #{n}" }
    sequence(:body) { |n| "Body of ISSUE #{n}" }
    sequence(:project_name) { |n| "test_user/repo_#{n}" }

    trait :partial do
      body { nil }
    end

    trait :open do
      state { "opened" }
    end

    trait :closed do
      state { "closed" }
    end
  end
end
