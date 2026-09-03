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

module BasicData
  module RiskManagement
    class Seeder < ::Seeder
      self.needs = [
        BasicData::ColorSeeder,
        BasicData::ColorSchemeSeeder
      ]

      RISK_TYPE_NAME = "Risk"
      RISK_STATUSES = {
        "New" => false,
        "Evaluated" => false,
        "Mitigation planned" => false,
        "Mitigation done" => false,
        "Occurred" => true,
        "Rejected" => true
      }.freeze
      RISK_STATUS_COLORS = {
        "New" => "cyan-7",
        "Evaluated" => "blue-2",
        "Mitigation planned" => "yellow-2",
        "Mitigation done" => "green-3",
        "Occurred" => "red-5",
        "Rejected" => "red-3"
      }.freeze
      RISK_WORKFLOW = RISK_STATUSES.keys.index_with { RISK_STATUSES.keys }.freeze
      RISK_CATEGORIES = [
        "Strategic",
        "Operational",
        "Financial",
        "Legal & compliance",
        "Technical",
        "Information security",
        "Schedule & planning",
        "Resources & people"
      ].freeze
      RISK_CATEGORY_COLORS = %w[blue-4 cyan-5 yellow-3 violet-3 blue-2 red-3 orange-3 green-3].freeze

      def seed_data!
        Type.transaction do
          risk_type = seed_risk_type
          seed_risk_categories
          risk_statuses = seed_risk_statuses
          configure_risk_type_form(risk_type)
          seed_risk_workflows(risk_type, risk_statuses)
          configure_risk_management
        end
      end

      def applicable?
        true
      end

      private

      def seed_risk_type
        Type.find_or_initialize_by(builtin_identifier: "risk").tap do |type|
          type.name = RISK_TYPE_NAME
          type.position = Type.maximum(:position).to_i + 1 if type.new_record?
          type.save!
        end
      end

      def seed_risk_categories
        RISK_CATEGORIES.zip(RISK_CATEGORY_COLORS).each_with_index do |(name, color_name), index|
          ::RiskManagement::RiskCategory.find_or_initialize_by(name:).tap do |category|
            category.assign_attributes(
              color: Color.find_by!(name: color_name),
              position: index + 1,
              active: true
            )
            category.save!
          end
        end
      end

      def configure_risk_type_form(risk_type)
        variant = risk_type.default_variant
        variant.attribute_groups = [
          [
            "risk_details",
            %w[
              subject description status assignee risk_owner risk_likelihood risk_impact risk_exposure
              risk_category_ids risk_response
            ],
            "Risk details"
          ]
        ]
        variant.save!
      end

      def seed_risk_statuses
        RISK_STATUSES.map.with_index do |(name, is_closed), index|
          (Status.find_by(name:) || Status.new(name:)).tap do |status|
            status.assign_attributes(
              is_closed:,
              is_default: name == "New",
              color: Color.find_by!(name: RISK_STATUS_COLORS.fetch(name)),
              position: status.position || (Status.maximum(:position).to_i + index + 1)
            )
            status.save!
          end
        end
      end

      def seed_risk_workflows(risk_type, statuses)
        statuses_by_name = statuses.index_by(&:name)

        Workflow.eligible_roles.find_each do |role|
          Workflow.where(type_variant: risk_type.default_variant, role:, old_status: statuses).delete_all

          RISK_WORKFLOW.each do |old_name, new_names|
            old_status = statuses_by_name.fetch(old_name)
            new_names.each do |new_name|
              new_status = statuses_by_name.fetch(new_name)
              Workflow.find_or_create_by!(
                type_variant: risk_type.default_variant,
                role:,
                old_status:,
                new_status:,
                author: false,
                assignee: false
              )
            end
          end
        end
      end

      def configure_risk_management
        configuration = ::RiskManagement::Configuration.new(
          impact_very_low_max: 10_000,
          impact_low_max: 50_000,
          impact_medium_max: 100_000,
          impact_high_max: 500_000
        )

        return if configuration.save

        raise "Could not configure risk management: #{configuration.errors.full_messages.to_sentence}"
      end
    end
  end
end
