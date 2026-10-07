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

module OpenProject
  module Common
    class BorderBoxListComponent
      # Standard inline title form for {Header}: a text field, Save and
      # Cancel. Field and buttons look the same for every list.
      #
      # This component is part of {BorderBoxListComponent} and should not be
      # used as a standalone component.
      class TitleForm < ApplicationComponent
        # @param url [String] form target.
        # @param label [String] field label, rendered visually hidden.
        # @param method [Symbol, nil] HTTP method of the form.
        # @param model [Object, nil] form model. Its errors render below the
        #   field unless `input_arguments[:validation_message]` is given.
        # @param scope [Symbol, nil] parameter scope of the form.
        # @param input_name [Symbol] name of the text field.
        # @param placeholder [String, nil] field placeholder.
        # @param hidden_fields [Hash] name to value, rendered as hidden
        #   inputs. `nil` values are skipped.
        # @param input_arguments [Hash] merged over the text field defaults.
        # @param cancel_arguments [Hash] merged over the Cancel button
        #   defaults. Carries its behavior (`href:`, `data:`, or `tag: :button`
        #   for a button); `href:` is required unless `tag: :button` is passed.
        #   Label and scheme are fixed.
        # @param system_arguments [Hash] forwarded to `primer_form_with`.
        def initialize(url:, label:, method: nil, model: nil, scope: nil, input_name: :title, placeholder: nil,
                       hidden_fields: {}, input_arguments: {}, cancel_arguments: {}, **system_arguments)
          super()

          @url = url
          @label = label
          @method = method
          @model = model
          @scope = scope
          @input_name = input_name
          @placeholder = placeholder
          @hidden_fields = hidden_fields
          @input_arguments = input_arguments
          @cancel_arguments = cancel_arguments
          @system_arguments = system_arguments

          resolved = self.cancel_arguments
          return unless resolved[:tag] == :a && resolved[:href].blank?

          raise ArgumentError,
                "Cancel needs a target: pass `cancel_arguments: { href: … }`, " \
                "or `tag: :button` with a `data:` action."
        end

        private

        def form_arguments
          { model: @model || false, scope: @scope, url: @url, method: @method }.compact.merge(@system_arguments)
        end

        def hidden_fields
          @hidden_fields.compact
        end

        def input_arguments
          {
            name: @input_name,
            label: @label,
            placeholder: @placeholder,
            visually_hide_label: true,
            required: true,
            autofocus: true,
            autocomplete: "off"
          }.compact.deep_merge(@input_arguments.deep_dup)
        end

        def cancel_arguments
          {
            name: :cancel,
            label: I18n.t(:button_cancel),
            scheme: :secondary,
            tag: :a
          }.deep_merge(@cancel_arguments.deep_dup.except(:scheme, :label, :name))
        end
      end
    end
  end
end
