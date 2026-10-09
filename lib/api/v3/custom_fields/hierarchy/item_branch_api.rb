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
        class ItemBranchAPI < ::API::OpenProjectAPI
          include Dry::Monads[:result]

          resource :branch do
            get do
              ::CustomFields::Hierarchy::HierarchicalItemService
                .new
                .get_branch(item: @custom_field_item)
                .fmap { |items| items.map { |item| HierarchicalItemAggregate.new(item:, depth: item.depth - 1) } }
                .either(
                  ->(items) do
                    self_link = api_v3_paths.custom_field_item_branch(@custom_field_item.id)
                    HierarchyItemCollectionRepresenter.new(items, self_link:, current_user:)
                  end,
                  ->(error) do
                    msg = "#{I18n.t('api_v3.errors.code_500')} #{error}"
                    raise ::API::Errors::SafeInternalError.new(msg)
                  end
                )
            end
          end
        end
      end
    end
  end
end
