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
  factory :meeting, class: "Meeting" do |m|
    author factory: :user
    project
    start_time { Date.tomorrow + 10.hours }
    recurring_meeting { nil }
    recurrence_start_time { nil }
    duration { 1.0 }
    location { "https://some-url.com" }
    m.sequence(:title) { |n| "Meeting #{n}" }

    trait :author_participates do
      after(:build) do |meeting|
        meeting.participants << build(:meeting_participant, meeting: meeting, user: meeting.author, invited: true)
      end
    end

    after(:create) do |meeting, evaluator|
      meeting.project = evaluator.project if evaluator.project

      # create backlog
      create(:meeting_section, meeting:, backlog: true, title: I18n.t(:label_agenda_backlog))
    end

    # A meeting occurrence that belongs to a recurring series.
    # Pass recurring_meeting: and start_time: when building.
    factory :recurring_meeting_occurrence do
      recurring_meeting
      recurrence_start_time { start_time }
      template { false }

      after(:build) do |meeting, evaluator|
        # Occurrences must inherit the series project/author to keep permissions consistent.
        meeting.project = evaluator.recurring_meeting.project
        meeting.author = evaluator.recurring_meeting.author
        meeting.title ||= evaluator.recurring_meeting.template&.title || "Occurrence"
        meeting.duration ||= evaluator.recurring_meeting.template&.duration || 1.0
      end

      trait :cancelled do
        state { :cancelled }
      end
    end

    factory :meeting_template do |meeting|
      meeting.sequence(:title) { |n| "Meeting template #{n}" }
      template { true }
      recurrence_start_time { nil }
      recurring_meeting

      after(:build) do |template, evaluator|
        %w[author project start_time].each do |attr|
          template.send(:"#{attr}=", evaluator.recurring_meeting.send(attr))
        end
      end
    end

    factory :onetime_template do |meeting|
      meeting.sequence(:title) { |n| "Onetime template #{n}" }
      template { true }
      recurring_meeting { nil }
      sharing { :none }
    end
  end
end
