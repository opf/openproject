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

module CustomFields
  module ProjectSpecificValues
    class MakeGlobalContract < ::BaseContract
      include RequiresAdminGuard

      validate :validate_value_of_project
      validate :validate_parent_global
      validate :validate_unique

      private

      def validate_value_of_project
        return if model.restrictable_values.exists?(id: value.id, project_id: options[:project].id)

        errors.add :value, :inclusion
      end

      def validate_parent_global
        return if model.list? || value.parent.project_id.nil?

        errors.add :value, :parent_only_in_project
      end

      def validate_unique
        errors.add :value, :taken if conflicting_values.exists?
      end

      def conflicting_values
        model.list? ? conflicting_options : conflicting_siblings
      end

      def conflicting_options
        model.custom_options.where.not(id: value.id).where("LOWER(value) = LOWER(?)", value.value)
      end

      def conflicting_siblings
        same_label = siblings.with_label_ignoring_case(value.label)
        return same_label if value.short.blank?

        same_label.or(siblings.with_short_ignoring_case(value.short))
      end

      def siblings
        value.parent.children.where.not(id: value.id)
      end

      def value
        options[:value]
      end
    end
  end
end
