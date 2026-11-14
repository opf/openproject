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
    class MoveItemContract < DryApplicationContract
      params do
        required(:item).filled(type?: CustomField::Hierarchy::Item)
        required(:parent).filled(type?: CustomField::Hierarchy::Item)
      end

      rule(:parent, :item) do
        next if schema_error?(:item) || schema_error?(:parent)

        parent = values[:parent]
        key(:parent).failure(:other_project) unless parent.project_id.nil? || parent.project_id == values[:item].project_id
      end

      rule(:parent, :item) do
        next if schema_error?(:item) || schema_error?(:parent)

        item = values[:item]
        siblings = conflicting_siblings(values[:parent], item)

        key(:label).failure(:not_unique) if siblings.with_label_ignoring_case(item.label).exists?
        key(:short).failure(:not_unique) if item.short && siblings.with_short_ignoring_case(item.short).exists?
      end

      private

      def conflicting_siblings(parent, item)
        siblings = parent.children.where.not(id: item.id)
        return siblings if item.project_id.nil?

        siblings.where(project_id: [nil, item.project_id])
      end
    end
  end
end
