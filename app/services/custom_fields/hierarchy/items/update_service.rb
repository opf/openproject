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
  module Hierarchy
    module Items
      class UpdateService < ::BaseServices::Update
        protected

        def persist(service_result)
          item = service_result.result
          return super unless item.parent_id_changed? || item.sort_order_changed?

          item.place_under(item.parent, before: requested_position(item))

          if item.errors.any?
            service_result.success = false
            service_result.errors = item.errors
            return service_result
          end

          service_result.merge!(RebuildPositionCacheService.new(user:, model: item).call)
        end

        def after_perform(service_result)
          item = service_result.result
          return service_result unless item.weight_previously_changed?

          service_result.merge!(
            RecalculateValuesService.new(user:, model: item.root.custom_field).call(item_ids: [item.id])
          )
        end

        private

        def requested_position(item)
          item.sort_order unless item.parent_id_changed?
        end
      end
    end
  end
end
