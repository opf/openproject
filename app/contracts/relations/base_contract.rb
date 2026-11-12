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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Relations
  class BaseContract < ::ModelContract
    attribute :relation_type
    attribute :lag
    attribute :description
    attribute :from
    attribute :to

    validate :validate_from_exists
    validate :validate_to_exists
    validate :validate_user_allowed
    validate :validate_nodes_relatable
    validate :validate_accepted_type

    def self.model
      Relation
    end

    private

    def validate_from_exists
      errors.add :from_id, :error_not_found unless visible_work_packages.exists? model.from_id
    end

    def validate_to_exists
      errors.add :to_id, :error_not_found unless visible_work_packages.exists? model.to_id
    end

    def validate_nodes_relatable
      # when creating a relation from the work package relations tab and not selecting a WorkPackage
      # the to_id is not set
      # in this case we only want to show the "WorkPackage can't be blank" error instead of a
      # misleading circular dependencies error
      # the error is added by the `validate_from_exists` and `validate_to_exists` methods
      return if to_id_or_from_id_nil?

      if relation_changed? && circular_dependency?
        errors.add :base, I18n.t(:"activerecord.errors.messages.circular_dependency")
      end
    end

    def validate_accepted_type
      return if (Relation::TYPES.keys + [Relation::TYPE_PARENT]).include?(model.relation_type)

      errors.add :relation_type, :inclusion
    end

    def validate_user_allowed
      # Only check if the work packages exist and are visible
      return if skip_validation?

      unless from_manageable?
        errors.add :from_id, :error_not_manageable
      end

      unless to_manageable?
        errors.add :to_id, :error_not_manageable
      end
    end

    def to_id_or_from_id_nil?
      model.to_id.nil? || model.from_id.nil?
    end

    def relation_changed?
      model.from_id_changed? || model.to_id_changed?
    end

    def circular_dependency?
      WorkPackage.relatable(model.from, model.relation_type, ignored_relation: model).where(id: model.to_id).empty?
    end

    def visible_work_packages
      ::WorkPackage.visible(user)
    end

    def from_manageable?
      user.allowed_in_work_package?(:manage_work_package_relations, model.from)
    end

    def to_manageable?
      user.allowed_in_work_package?(:manage_work_package_relations, model.to)
    end

    def skip_validation?
      model.to_id.nil? || model.from_id.nil? || errors[:from_id].any? || errors[:to_id].any?
    end
  end
end
