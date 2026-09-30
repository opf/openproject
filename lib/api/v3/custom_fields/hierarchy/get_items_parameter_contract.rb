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

module API
  module V3
    module CustomFields
      module Hierarchy
        class GetItemsParameterContract < DryApplicationContract
          option :hierarchy_root

          params do
            optional(:parent).filled(:integer)
            optional(:depth).filled(:integer)
          end

          rule(:parent) do
            next unless key?

            parent_item = ::CustomField::Hierarchy::Item.find_by(id: value)

            if parent_item.nil?
              key.failure(:not_found)
            elsif persistence_service.descendant_of?(item: parent_item, parent: hierarchy_root).failure?
              key.failure(:not_descendant)
            end
          end

          rule(:depth) do
            next unless key?

            key.failure(:greater_or_equal_zero) if value < 0
          end

          private

          def persistence_service
            @persistence_service ||= ::CustomFields::Hierarchy::HierarchicalItemService.new
          end
        end
      end
    end
  end
end
