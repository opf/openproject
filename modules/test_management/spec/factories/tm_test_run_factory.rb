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
  factory :tm_test_run, class: "TestManagement::TestRun" do
    project
    sequence(:name) { |n| "Run #{n}" }
    state { "new" }
    selection_mode { "specific" }
    filter_options { {} }
    author factory: :user

    trait :in_progress do
      state { "in_progress" }
    end

    trait :completed do
      state { "completed" }
      finished_at { Time.current }
    end

    trait :cancelled do
      state { "cancelled" }
      finished_at { Time.current }
    end

    trait :automation do
      source { "automation" }
      sequence(:external_ref) { |n| "github:my-org/shop:#{1000 + n}:1" }
      ci_metadata { { "provider" => "github", "branch" => "main", "commitSha" => "3f9c2d1e0a7b" } }
    end
  end

  factory :tm_test_run_case, class: "TestManagement::TestRunCase" do
    test_run factory: :tm_test_run
    test_case { association :tm_test_case, project: test_run.project }
    status { "untested" }
  end

  factory :tm_test_result, class: "TestManagement::TestResult" do
    run_case factory: :tm_test_run_case
    status { "passed" }
    user
  end

  factory :tm_automation_import, class: "TestManagement::AutomationImport" do
    test_run factory: :tm_test_run
    project { test_run.project }
    user
    add_attribute(:format) { "playwright_json" }
    state { "done" }
    sequence(:digest) { |n| Digest::SHA256.hexdigest("report #{n}") }
  end

  factory :tm_test_run_iteration, class: "TestManagement::TestRunIteration" do
    test_run factory: :tm_test_run
    sequence(:number) { |n| n }
    source { "manual" }
    ci_metadata { {} }
  end
end
