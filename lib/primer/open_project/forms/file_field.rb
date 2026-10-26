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

module Primer
  module OpenProject
    module Forms
      # :nodoc:
      class FileField < Primer::Forms::BaseComponent
        prepend WrappedInput

        delegate :builder, :form, :name, :label, :description, :icon, :accept, :preview_url, :preview_class,
                 :preview_data, :filename, :delete_path, to: :@input

        def initialize(input:)
          super()
          @input = input
        end

        def preview_attributes
          {
            class: class_names("FormControl-file-field-preview", preview_class),
            alt: "",
            src: preview_url,
            data: { "file-field-target": "preview" }.merge(preview_data)
          }.compact
        end

        # Files that cannot be previewed as an image (e.g. fonts) still need
        # the replace/delete menu once one is already uploaded.
        def has_attachment?
          preview_url.present? || filename.present?
        end

        def displayed_label
          filename.presence || label
        end

        def field_wrap_arguments
          @field_wrap_arguments.merge(
            class: class_names(
              @field_wrap_arguments[:class],
              "FormControl-file-field-wrap",
              "FormControl-file-field-wrap--has-preview" => preview_url.present?
            )
          )
        end

        def menu_label
          I18n.t(:button_actions)
        end

        def file_input_actions
          actions = ["change->file-field#fileChosen"]
          actions << "change->auto-submit#submit" if @input.auto_submit

          actions.join(" ")
        end

        def replace_item_arguments
          {
            label: I18n.t(:button_replace),
            content_arguments: { data: { action: "click->file-field#openFilePicker" } }
          }
        end

        def delete_item_arguments
          {
            label: I18n.t(:button_delete),
            scheme: :danger,
            href: delete_path,
            content_arguments: @input.delete_button_arguments
          }
        end
      end
    end
  end
end
