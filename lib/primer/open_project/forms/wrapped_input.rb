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
      # Prepend this module to a subclass of Primer::Forms::BaseComponent.
      # Together with a corresponding dom element in the template this will wrap the input field in
      # the classes expected by the Primer CSS framework.
      # The template of the prepended to class would look like this:
      #
      # <%= render(FormControl.new(input: @input)) do %>
      #   <%= content_tag(:div, **@field_wrap_arguments) do %>
      #     ... actual input field here ...
      #   <% end %>
      # <% end %>
      module WrappedInput
        extend ActiveSupport::Concern

        included do
          raise "This module needs to be prepended."
        end

        def initialize(**)
          super

          set_field_wrap_arguments
        end

        def set_field_wrap_arguments
          wrap_classes = [
            "FormControl-input-wrap"
          ]
          wrap_classes << Primer::Forms::Dsl::Input::INPUT_WIDTH_MAPPINGS[@input.input_width] if @input.input_width

          @field_wrap_arguments = {
            class: class_names(wrap_classes),
            hidden: @input.hidden?
          }
        end
      end
    end
  end
end
