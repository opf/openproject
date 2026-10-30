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

module CustomFields
  module ProjectSpecificValues
    # Subclasses decide which values end up usable in the project. This base class stores that
    # set as the restriction rows of the custom field's mode, so the same set always results in
    # the same rows.
    class BaseService < ::BaseServices::BaseContracted
      def initialize(user:, model:, contract_class: BaseContract)
        super(user:, contract_class:)
        self.model = model
      end

      private

      def usable_value_ids
        raise SubclassResponsibilityError
      end

      def persist(service_call)
        listed_ids = listed_value_ids(usable_value_ids.to_set)

        delete_outdated_restrictions(listed_ids)
        insert_restrictions(listed_ids - restrictions.pluck(value_column))
        invalidate_cached_work_packages

        service_call
      end

      def listed_value_ids(usable_ids)
        if model.project_specific_value_restriction_allow?
          usable_ids.to_a
        else
          blocked_value_ids(usable_ids)
        end
      end

      # A blocked item takes its whole subtree with it, so only the topmost unusable items need a row.
      def blocked_value_ids(usable_ids)
        unusable_ids = value_ids.reject { usable_ids.include?(it) }
        return unusable_ids if model.list?

        unusable_ids.select { |id| parent_ids[id] == model.hierarchy_root.id || usable_ids.include?(parent_ids[id]) }
      end

      # Cached work package representations are keyed by the custom fields they render.
      def invalidate_cached_work_packages
        model.touch
      end

      def delete_outdated_restrictions(listed_ids)
        restrictions.where.not(value_column => listed_ids)
                    .or(restrictions.where.not(restriction: mode))
                    .delete_all
      end

      def insert_restrictions(ids)
        return if ids.empty?

        CustomField::ProjectSpecificValueRestriction.insert_all(
          ids.map { |id| { project_id: project.id, custom_field_id: model.id, restriction: mode, value_column => id } }
        )
      end

      def currently_usable_ids
        model.usable_values_in(project).pluck(:id)
      end

      def value_ids
        model.list? ? model.custom_options.pluck(:id) : parent_ids.keys
      end

      def parent_ids
        @parent_ids ||= model.restrictable_values.pluck(:id, :parent_id).to_h
      end

      def restrictions
        model.project_specific_value_restrictions.where(project:)
      end

      def value_column
        model.list? ? :custom_option_id : :hierarchy_item_id
      end

      def mode
        model.project_specific_value_restriction
      end

      def project
        params[:project]
      end
    end
  end
end
