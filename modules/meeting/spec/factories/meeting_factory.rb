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
    duration { 1.0 }
    location { "https://some-url.com" }
    m.sequence(:title) { |n| "Meeting #{n}" }

    after(:create) do |meeting, evaluator|
      meeting.project = evaluator.project if evaluator.project
    end

    factory :structured_meeting, class: "StructuredMeeting" do |m|
      m.sequence(:title) { |n| "Structured meeting #{n}" }
    end
  end
end
