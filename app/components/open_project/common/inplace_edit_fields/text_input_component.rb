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
      class TextInputComponent < BaseFieldComponent
        def call
          @system_arguments[:data] = merge_data(
            @system_arguments,
            **additional_arguments
          )

          form.text_field name: attribute,
                          autofocus: true,
                          **@system_arguments

          comment_field_if_enabled(form)
        end

        private

        def reset_url
          inplace_edit_field_reset_path(
            model: model.class.name,
            id: model.id,
            attribute:,
            system_arguments_json: @system_arguments.to_json
          )
        end

        def additional_arguments
          if show_action_buttons
            {
              data: { controller: "inplace-edit",
                      inplace_edit_url_value: reset_url,
                      action: "keydown.esc->inplace-edit#request",
                      test_selector: }
            }
          else
            { data: { test_selector: } }
          end
        end
      end
    end
  end
end
