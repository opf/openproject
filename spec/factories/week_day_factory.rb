#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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
  factory :week_day do
    sequence :day, [1, 2, 3, 4, 5, 6, 7].cycle
    working { day < 6 }

    # hack to reuse the day if it already exists in database
    to_create do |instance|
      instance.attributes = WeekDay.find_or_create_by(instance.attributes.slice("day", "working")).attributes
      instance.instance_variable_set('@new_record', false)
    end

    trait :tuesday do
      day { 2 }
    end
  end

  # Factory to create all 7 week days at once, Saturday and Sunday being weekend days
  factory :week_with_saturday_and_sunday_as_weekend, aliases: [:week_days], parent: :week do
    working_days { %w[monday tuesday wednesday thursday friday] }
  end

  # Factory to create all 7 week days at once
  #
  # use +working: ['monday', 'tuesday', ...]+ to define which days of the week
  # will be working days. By default, all days are working days.
  factory :week, class: 'Array' do
    transient do
      working_days { %w[monday tuesday wednesday thursday friday saturday sunday] }
    end

    # Skip the create callback to be able to use non-AR models. Otherwise FactoryBot will
    # try to call #save! on any created object.
    skip_create

    initialize_with do
      %w[monday tuesday wednesday thursday friday saturday sunday]
        .map.with_index do |day_name, i|
          day = i + 1
          working = working_days.include?(day_name)
          create(:week_day, day:, working:)
        end
    end
  end
end
