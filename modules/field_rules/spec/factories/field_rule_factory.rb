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
  factory :field_rule_set do
    sequence(:name) { |n| "Rule set #{n}" }
    active { true }

    transient { rule_attributes { [] } }

    after(:build) do |rule_set, evaluator|
      evaluator.rule_attributes.each_with_index do |attributes, index|
        rule_set.rules.build({ position: index }.merge(attributes))
      end
    end
  end

  factory :field_rule_scheme do
    sequence(:name) { |n| "Field scheme #{n}" }
    active { true }

    transient { mapping { {} } }

    after(:build) do |scheme, evaluator|
      evaluator.mapping.each { |type, rule_set| scheme.items.build(type:, rule_set:) }
    end
  end
end
