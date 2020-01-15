#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

FactoryBot.define do
  factory :type do
    sequence(:position) { |p| p }
    name { |a| "Type No. #{a.position}" }
    description { nil }
    created_at { Time.now }
    updated_at { Time.now }

    factory :type_with_workflow, class: Type do
      callback(:after_build) do |t|
        t.workflows = [FactoryBot.build(:workflow_with_default_status)]
      end
    end

    factory :type_with_relation_query_group, class: Type do
      transient do
        relation_filter { 'parent' }
      end

      callback(:after_build) do |t, evaluator|
        query = FactoryBot.create(:query)
        query.add_filter(evaluator.relation_filter.to_s, '=', [::Queries::Filters::TemplatedValue::KEY])
        query.save
        t.attribute_groups = t.default_attribute_groups + [["Embedded table for #{evaluator.relation_filter.to_s}", ["query_#{query.id}".to_sym]]]
      end
    end
  end

  factory :type_standard, class: ::Type do
    name { 'None' }
    is_standard { true }
    is_default { true }
    created_at { Time.now }
    updated_at { Time.now }
  end

  factory :type_bug, class: ::Type do
    name { 'Bug' }
    position { 1 }
    created_at { Time.now }
    updated_at { Time.now }

    # reuse existing type with the given name
    # this prevents a validation error (name has to be unique)
    initialize_with { ::Type.find_or_initialize_by(name: name) }

    factory :type_feature do
      name { 'Feature' }
      position { 2 }
      is_default { true }
    end

    factory :type_support do
      name { 'Support' }
      position { 3 }
    end

    factory :type_task do
      name { 'Task' }
      position { 4 }
    end
  end
end
