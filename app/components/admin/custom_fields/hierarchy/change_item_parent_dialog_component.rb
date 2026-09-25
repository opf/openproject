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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Admin
  module CustomFields
    module Hierarchy
      class ChangeItemParentDialogComponent < ApplicationComponent
        include OpTurbo::Streamable
        include CustomFieldHierarchyTreeViewHelper
        include ItemRoutes

        TEST_SELECTOR = "op-custom-fields--change-item-parent-dialog"

        def initialize(custom_field:, hierarchy_item:)
          super
          @custom_field = custom_field
          @hierarchy_item = hierarchy_item
        end

        def dialog_id = "custom-fields--change-item-parent-dialog"

        def form_id = "custom-fields--change-item-parent-form"

        def form_arguments
          {
            id: form_id,
            url:,
            model: form_model,
            method: :post
          }
        end

        def hierarchy_service
          @hierarchy_service ||= ::CustomFields::Hierarchy::HierarchicalItemService.new
        end

        private

        def form_model
          CustomField::Hierarchy::Forms::NewParentFormModel.new(new_parent: [])
        end

        attr_reader :custom_field

        def url = hierarchy_item_path(@hierarchy_item, :change_parent)
      end
    end
  end
end
