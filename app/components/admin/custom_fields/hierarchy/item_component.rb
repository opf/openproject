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

module Admin
  module CustomFields
    module Hierarchy
      class ItemComponent < ApplicationComponent
        include OpTurbo::Streamable
        include OpPrimer::ComponentHelpers

        def initialize(root:, item:)
          super(item)
          @root = root
        end

        def wrapper_uniq_by
          model.id
        end

        def short_text
          "(#{model.short})"
        end

        def children_count
          I18n.t("custom_fields.admin.hierarchy.subitems", count: model.children.count)
        end

        def deletion_action_item(menu)
          menu.with_item(label: I18n.t(:button_delete),
                         scheme: :danger,
                         tag: :a,
                         href: deletion_dialog_custom_field_item_path(custom_field_id: @root.custom_field_id, id: model.id),
                         content_arguments: { data: { controller: "async-dialog" } }) do |item|
            item.with_leading_visual_icon(icon: :trash)
          end
        end
      end
    end
  end
end
