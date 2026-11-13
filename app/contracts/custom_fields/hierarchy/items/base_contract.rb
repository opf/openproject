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
  module Hierarchy
    module Items
      class BaseContract < ::ModelContract
        include RequiresAdminGuard

        attribute :label
        attribute :short
        attribute :weight
        attribute :parent_id
        attribute :sort_order

        validates :label, presence: true
        validates :weight, presence: true, if: :weighted_item_list?
        validate :validate_parent_present
        validate :validate_parent_in_hierarchy, if: :parent_moved?
        validate :validate_parent_in_project, if: :parent?
        validate :validate_unique_label, if: :parent?
        validate :validate_unique_short, if: :parent?

        private

        def validate_parent_present
          errors.add(:parent, :blank) unless parent?
        end

        def validate_parent_in_hierarchy
          if model.parent.root != model.root
            errors.add(:parent, :other_hierarchy)
          elsif model.parent == model || model.parent.descendant_of?(model)
            errors.add(:parent, :own_descendant)
          end
        end

        def validate_parent_in_project
          return if model.parent.project_id.nil? || model.parent.project_id == model.project_id

          errors.add(:parent, :other_project)
        end

        def validate_unique_label
          errors.add(:label, :not_unique) if conflicting_siblings.with_label_ignoring_case(model.label).exists?
        end

        def validate_unique_short
          return if model.short.nil?

          errors.add(:short, :not_unique) if conflicting_siblings.with_short_ignoring_case(model.short).exists?
        end

        def conflicting_siblings
          siblings = model.parent.children.where.not(id: model.id)
          return siblings if model.project_id.nil?

          siblings.where(project_id: [nil, model.project_id])
        end

        def parent?
          model.parent.present?
        end

        def parent_moved?
          parent? && model.persisted? && model.parent_id_changed?
        end

        def weighted_item_list?
          custom_field&.field_format_weighted_item_list?
        end

        def custom_field
          model.parent&.root&.custom_field
        end
      end
    end
  end
end
