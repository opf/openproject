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
      class RichTextAreaComponent < BaseFieldComponent
        def self.display_class
          DisplayFields::RichTextAreaComponent
        end

        def initialize(form:, attribute:, model:, show_action_buttons: true, **system_arguments)
          super
          @system_arguments[:classes] = class_names(
            @system_arguments[:classes],
            "op-inplace-edit-field--text-area"
          )

          @system_arguments[:rich_text_options] ||= {}
          @system_arguments[:rich_text_options][:primerized] = true
          # Text custom fields offer the wiki-page-link macros (AC: "custom field of type text").
          @system_arguments[:rich_text_options][:macros] ||= "wiki" if custom_field?

          @system_arguments[:data] = merge_data(
            @system_arguments,
            data: { test_selector: }
          )
        end

        def call
          form.rich_text_area(name: attribute,
                              wrapper_data_attributes: ckeditor_wrapper_data,
                              **@system_arguments)

          comment_field_if_enabled(form)
          render_action_buttons(form) if show_action_buttons
        end

        def test_selector
          if custom_field?
            "custom-field-#{custom_field.id}"
          else
            "augmented-text-area-#{attribute.to_s.parameterize(separator: '_')}"
          end
        end

        private

        def ckeditor_wrapper_data
          {
            controller: "ckeditor-focus",
            ckeditor_focus_target: "editor",
            ckeditor_focus_autofocus_value: true
          }
        end

        def cancel_button_options
          super.merge(test_selector: "op-inplace-edit-field--textarea-cancel")
        end

        def submit_button_options
          { test_selector: "op-inplace-edit-field--textarea-save" }
        end
      end
    end
  end
end
