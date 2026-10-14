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
  factory :ai_assistant, class: "AI::Assistant" do
    sequence(:name) { |n| "Assistant #{n}" }
    description { "Checks work packages." }
    icon { "checklist" }
    sequence(:position)
  end

  factory :ai_assistant_skill, class: "AI::AssistantSkill" do
    assistant { association :ai_assistant }
    skill_key { "conversation" }
    first_message { "Refresh this work package." }
    checks { true }
    prompt { "Check the work package for contradictions." }
    sequence(:position)

    trait :chat do
      first_message { nil }
      checks { false }
    end

    trait :preset do
      first_message { "Write a test plan." }
      checks { false }
    end
  end

  factory :ai_assistant_run, class: "AI::AssistantRun" do
    skill { association :ai_assistant_skill }
    user
    work_package
    work_package_lock_version { work_package.lock_version }
    locale { "en" }

    trait :finished do
      status { "finished" }
    end
  end

  factory :ai_assistant_run_finding, class: "AI::AssistantRunFinding" do
    run { association :ai_assistant_run }
    source { "rule" }
    rule_key { "closed_with_open_descendants" }
    severity { "high" }
    area { "tree" }
    text { "This work package is closed, but 1 descendant is still open." }
    evidence { [{ "text" => "#1", "work_package_id" => 1 }] }

    trait :with_change_set do
      source { "ai" }
      rule_key { nil }
      change_set { AI::Proposal.change_set_for({ "description" => "A better description" }) }
      base_lock_version { run.work_package_lock_version }
    end
  end

  factory :ai_assistant_chat, class: "AI::AssistantChat" do
    skill { association :ai_assistant_skill, :chat }
    user
    work_package
  end

  factory :ai_assistant_chat_message, class: "AI::AssistantChatMessage" do
    chat { association :ai_assistant_chat }
    role { "assistant" }
    content { "An answer." }
    locale { "en" }
    base_lock_version { chat.work_package.lock_version }
  end

  factory :ai_assistant_proposal, class: "AI::AssistantProposal" do
    message { association :ai_assistant_chat_message }
    source { "ai" }
    change_set { AI::Proposal.change_set_for({ "description" => "A better description" }) }
    base_lock_version { message.base_lock_version }

    trait :finding do
      severity { "medium" }
      area { "content" }
      text { "The description misses the latest decision." }
      evidence { [{ "text" => "A comment" }] }
    end
  end
end
