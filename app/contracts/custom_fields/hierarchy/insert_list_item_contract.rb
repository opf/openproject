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
    class InsertListItemContract < DryApplicationContract
      params do
        required(:parent).filled(type?: CustomField::Hierarchy::Item)
        required(:label).filled(:string)
        required(:short).maybe(:string)
        optional(:project).maybe(type?: Project)
      end

      rule(:parent) do
        next if schema_error?(:parent)

        key.failure("must exist") unless value.persisted?
      end

      rule(:parent, :project) do
        next if schema_error?(:parent) || schema_error?(:project)

        key(:parent).failure(:other_project) unless parent_in_reach?(values[:parent], values[:project])
      end

      rule(:project) do
        next if value.nil? || schema_error?(:parent)

        key.failure(:additional_values_not_allowed) unless values[:parent].root.custom_field.allow_additional_project_values
      end

      rule(:label) do
        next if schema_error?(:parent) || schema_error?(:project)

        siblings = conflicting_siblings(values[:parent], values[:project])
        key.failure(:not_unique) if siblings.with_label_ignoring_case(value).exists?
      end

      rule(:short) do
        next if schema_error?(:parent) || schema_error?(:project)
        next if value.nil?

        siblings = conflicting_siblings(values[:parent], values[:project])
        key.failure(:not_unique) if siblings.with_short_ignoring_case(value).exists?
      end

      private

      def parent_in_reach?(parent, project)
        parent.project_id.nil? || parent.project_id == project&.id
      end

      def conflicting_siblings(parent, project)
        return parent.children if project.nil?

        parent.children.where(project: [nil, project])
      end
    end
  end
end
