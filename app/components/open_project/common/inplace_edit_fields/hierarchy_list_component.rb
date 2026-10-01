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

module OpenProject
  module Common
    module InplaceEditFields
      class HierarchyListComponent < BaseFieldComponent
        include CustomFieldHierarchyTreeViewHelper

        def self.display_class
          DisplayFields::HierarchyListComponent
        end

        def self.open_in_dialog?
          true
        end

        def initialize(form:, attribute:, model:, show_action_buttons: false, **system_arguments)
          super
        end

        def call
          form_field_name = "project[custom_field_values][]"

          form.hidden(name: form_field_name, value: "", scope_name_to_model: false)
          filterable_tree_view(form)
          comment_field_if_enabled(form)
        end

        private

        def filterable_tree_view(form)
          form.html_content do
            render(Primer::OpenProject::FilterableTreeView.new(
                     form_arguments: { builder: rails_builder, name: "custom_field_values" },
                     include_sub_items_check_box_arguments: { hidden: true },
                     filter_mode_control_arguments: { hidden: true }
                   )) do |tree_view|
              item_options = {
                expanded_fn: ->(*) { true },
                label_fn:,
                checked_fn:,
                select_variant: custom_field.multi_value? ? :multiple : :single
              }

              populate_tree_view(tree_view, custom_field, item_options:)
            end
          end
        end

        # Primer's FormObject stores the underlying ActionView/Primer form builder
        # as @builder. FilterableTreeView requires an ActionView::FormBuilder to
        # generate its hidden form inputs via hidden_field.
        def rails_builder
          form.instance_variable_get(:@builder)
        end

        def checked_fn
          current_values = Array(model.custom_value_for(custom_field)).map(&:value)
          lambda { |item| current_values.include?(item.id.to_s) }
        end

        def label_fn
          item_formatter = standard_tree_view_item_formatter
          lambda { |item| item_formatter.format(item:) }
        end
      end
    end
  end
end
