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

module CostEntries
  class BaseContract < ::ModelContract
    delegate :entity,
             :project,
             :new_record?,
             to: :model

    def self.model
      CostEntry
    end

    validate :validate_units_are_in_range
    validate :validate_project_is_set
    validate :validate_entity
    validate :validate_user
    validate :validate_cost_type

    validates :spent_on,
              date: { before_or_equal_to: Proc.new { Date.new(9999, 12, 31) },
                      allow_blank: true },
              unless: Proc.new { spent_on.blank? }

    attribute :project_id
    attribute :entity_id
    attribute :entity_type
    attribute :cost_type_id
    attribute :user_id
    attribute :units
    attribute :overridden_costs
    attribute :comments
    attribute :spent_on
    # Aggregation columns derived from spent_on by the model
    attribute :tyear
    attribute :tmonth
    attribute :tweek

    private

    def validate_units_are_in_range
      errors.add :units, :invalid if model.units&.negative?
    end

    def validate_project_is_set
      errors.add :project_id, :invalid if model.project.nil?
    end

    def validate_entity
      return if model.entity.nil?

      errors.add :entity, :invalid if entity_invisible? || entity_not_in_project?
    end

    def validate_user # rubocop:disable Metrics/AbcSize
      return unless model.user || model.user_id_changed?
      return if model.user == model.logged_by

      if model.user.nil?
        errors.add :user_id, :blank
      elsif !model.user.visible?(user)
        errors.add :user_id, :invalid
      end
    end

    def validate_cost_type
      return if model.cost_type_id.blank?

      errors.add :cost_type_id, :invalid if model.cost_type.nil? || model.cost_type.deleted_at.present?
    end

    def entity_invisible?
      model.entity.nil? || !model.entity.visible?(user)
    end

    def entity_not_in_project?
      model.entity && model.project != model.entity.project
    end
  end
end
