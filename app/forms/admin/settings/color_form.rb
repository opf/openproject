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
  module Settings
    class ColorForm < ApplicationForm
      form do |color_form|
        color_form.text_field(
          name: :name,
          label: attribute_name(:name),
          required: true,
          validation_message: validation_message_for(:name),
          input_width: :medium
        )

        color_form.group(layout: :horizontal, classes: "color--hexcode-form-row") do |hexcode_group|
          hexcode_group.text_field(
            name: :hexcode,
            label: attribute_name(:hexcode),
            required: true,
            autocomplete: "off",
            validation_message: validation_message_for(:hexcode),
            input_width: :small
          )

          if show_swatch?
            hexcode_group.html_content do
              render(Colors::DefaultColorSwatchComponent.new(color: model, classes: "color--hexcode-form-swatch"))
            end
          end
        end

        color_form.group(layout: :horizontal) do |button_group|
          button_group.button(
            name: :cancel,
            scheme: :default,
            tag: :a,
            href: cancel_path,
            label: I18n.t(:button_cancel)
          )

          button_group.submit(
            name: :submit,
            scheme: :primary,
            label: I18n.t(:button_save)
          )
        end
      end

      private

      def cancel_path
        url_helpers.custom_style_path(tab: :default_colors)
      end

      def show_swatch?
        model.hexcode.present? && model.errors.messages_for(:hexcode).empty?
      end

      def validation_message_for(attribute)
        model.errors.messages_for(attribute).to_sentence.presence
      end
    end
  end
end
