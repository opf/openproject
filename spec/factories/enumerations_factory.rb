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
  factory :default_enumeration, class: "Enumeration" do
    initialize_with do
      Enumeration.where(type: "Enumeration", is_default: true).first || Enumeration.new
    end

    active { true }
    is_default { true }
    type { "Enumeration" }
    name { "Default Enumeration" }
  end

  factory :activity, class: "TimeEntryActivity" do
    sequence(:name) { |i| "Activity #{i}" }
    active { true }
    is_default { false }

    factory :inactive_activity do
      active { false }
    end
    factory :default_activity do
      is_default { true }
    end
  end

  factory :priority, class: "IssuePriority" do
    sequence(:name) { |i| "Priority #{i}" }
    active { true }

    factory :priority_low do
      name { "Low" }

      # reuse existing priority with the given name
      # this prevents a validation error (name has to be unique)
      initialize_with { IssuePriority.find_or_create_by(name:) }

      factory :priority_normal do
        name { "Normal" }
      end

      factory :priority_high do
        name { "High" }
      end

      factory :priority_urgent do
        name { "Urgent" }
      end

      factory :priority_immediate do
        name { "Immediate" }
      end
    end
  end
end
