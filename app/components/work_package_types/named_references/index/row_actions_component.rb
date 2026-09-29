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

module WorkPackageTypes
  module NamedReferences
    module Index
      class RowActionsComponent < ApplicationComponent
        include OpPrimer::ComponentHelpers

        def initialize(record:, model_class:, icon:)
          super()

          @record = record
          @model_class = model_class
          @icon = icon
        end

        def menu_id = "#{dom_class(model_class)}-#{record.id}-action-menu"

        def menu_label = model_class.reference_t("index.actions.menu", name: record.name)

        private

        attr_reader :record, :model_class, :icon

        def record_actions(menu)
          edit_action(menu)
          rename_action(menu)
          menu.with_divider
          delete_action(menu)
        end

        def edit_action(menu)
          menu.with_item(tag: :a,
                         label: model_class.reference_t("index.actions.edit"),
                         href: edit_polymorphic_path(record)) do |item|
            item.with_leading_visual_icon(icon:)
          end
        end

        def rename_action(menu)
          menu.with_item(tag: :a,
                         label: model_class.reference_t("index.actions.rename"),
                         href: polymorphic_path([:edit_dialog, record]),
                         content_arguments: { data: { controller: "async-dialog" } },
                         test_selector: "#{dom_class(model_class)}-rename-action") do |item|
            item.with_leading_visual_icon(icon: :pencil)
          end
        end

        def delete_action(menu)
          menu.with_item(tag: :button,
                         scheme: :danger,
                         label: t(:button_delete),
                         href: polymorphic_path(record),
                         form_arguments: { method: :delete, data: { confirm: t(:text_are_you_sure) } }) do |item|
            item.with_leading_visual_icon(icon: :trash)
          end
        end
      end
    end
  end
end
