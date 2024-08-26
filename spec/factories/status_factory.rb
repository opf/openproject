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
  factory :status do
    sequence(:name) { |n| "status #{n}" }
    is_closed { false }
    is_readonly { false }
    excluded_from_totals { false }

    trait :excluded_from_totals do
      excluded_from_totals { true }
    end

    factory :closed_status do
      is_closed { true }
    end

    factory :rejected_status do
      excluded_from_totals
      name { "Rejected" }
    end

    factory :default_status do
      is_default { true }
    end

    trait :readonly do
      is_readonly { true }
    end

    transient do
      workflow_for_type { nil }
    end

    callback(:after_create) do |status, evaluator|
      if evaluator.workflow_for_type
        create(:workflow, type: evaluator.workflow_for_type, old_status: status)
      end
    end
  end
end
