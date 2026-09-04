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
  factory :bim_link_template, class: 'Bim::LinkTemplate' do
    sequence(:name) { |n| "Link Template #{n}" }
    description { 'A template for creating element links' }
    relationship_type { :affected_by }
    element_filters do
      {
        'types' => ['IfcWall', 'IfcSlab'],
        'locations' => {
          'storey' => ['Level 1']
        }
      }
    end
    template_data { {} }
    auto_apply { false }
    public { false }

    association :project
    association :author, factory: :user

    # Relationship type traits
    trait :affected_by do
      relationship_type { :affected_by }
    end

    trait :responsible_for do
      relationship_type { :responsible_for }
    end

    trait :depends_on do
      relationship_type { :depends_on }
    end

    trait :observes do
      relationship_type { :observes }
    end

    trait :related_to do
      relationship_type { :related_to }
    end

    # Feature traits
    trait :auto_apply do
      auto_apply { true }
    end

    trait :public_template do
      public { true }
      project { nil }
    end

    # Filter combination traits
    trait :walls_only do
      element_filters do
        {
          'types' => ['IfcWall']
        }
      end
    end

    trait :structural_elements do
      element_filters do
        {
          'types' => ['IfcWall', 'IfcColumn', 'IfcBeam'],
          'tags' => ['structural']
        }
      end
    end

    trait :level_1_elements do
      element_filters do
        {
          'locations' => {
            'storey' => ['Level 1']
          }
        }
      end
    end

    trait :with_classifications do
      element_filters do
        {
          'types' => ['IfcWall'],
          'classifications' => [
            { 'system' => 'Uniclass', 'code' => 'Ss_25_10_20' }
          ]
        }
      end
    end

    trait :with_property_filters do
      element_filters do
        {
          'types' => ['IfcWall'],
          'properties' => {
            'LoadBearing' => 'True',
            'Height' => { 'gte' => 3.0 }
          }
        }
      end
    end

    trait :complex_filters do
      element_filters do
        {
          'types' => ['IfcWall', 'IfcColumn'],
          'locations' => {
            'storey' => ['Level 1', 'Level 2'],
            'building' => ['Building A']
          },
          'classifications' => [
            { 'system' => 'Uniclass', 'code' => 'Ss_25_10_20' }
          ],
          'properties' => {
            'LoadBearing' => 'True'
          },
          'tags' => ['structural', 'external']
        }
      end
    end
  end
end
