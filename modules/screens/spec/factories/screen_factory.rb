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
# frozen_string_literal: true

FactoryBot.define do
  factory :screen do
    sequence(:name) { |n| "Screen #{n}" }
    description { nil }
    screen_type { "create" }
    active { true }

    factory :create_screen do
      screen_type { "create" }
    end

    factory :edit_screen do
      screen_type { "edit" }
    end

    factory :view_screen do
      screen_type { "view" }
    end

    factory :transition_screen do
      screen_type { "transition" }
    end
  end

  factory :screen_section do
    screen
    sequence(:name) { |n| "Section #{n}" }
    position { 0 }
  end

  factory :screen_item do
    screen
    section { association(:screen_section, screen:) }
    sequence(:field_key) { |n| "field_#{n}" }
    position { 0 }
    width { "full" }
    visible { true }
  end

  factory :screen_scheme do
    sequence(:name) { |n| "Screen scheme #{n}" }
    description { nil }
    active { true }
  end

  factory :screen_scheme_item do
    scheme { association(:screen_scheme) }
    type
    create_screen { association(:create_screen) }
  end

  factory :project_screen_scheme do
    project
    scheme
  end
end
