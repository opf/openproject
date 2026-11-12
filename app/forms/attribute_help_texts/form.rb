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

module AttributeHelpTexts
  class Form < ApplicationForm
    form do |attribute_form|
      attribute_form.hidden(
        name: :type,
        value: model.type
      )

      if hide_attribute_name?
        attribute_form.hidden(
          name: :attribute_name,
          value: model.attribute_name
        )
      else
        attribute_form.select_list(
          name: :attribute_name,
          label: attribute_name(:attribute_name),
          required: true,
          disabled: model.persisted?
        ) do |list|
          selectable_attributes.each do |label, value|
            list.option(
              label:,
              value:,
              selected: value == model.attribute_name
            )
          end
        end
      end

      attribute_form.text_field(
        name: :caption,
        caption: I18n.t("attribute_help_texts.caption"),
        label: attribute_name(:caption),
        required: false
      )

      attribute_form.rich_text_area(
        name: :help_text,
        label: attribute_name(:help_text),
        required: true,
        rich_text_options: {
          showAttachments: true,
          primerized: true,
          resource: ::API::V3::HelpTexts::HelpTextRepresenter.new(
            model,
            current_user: User.current,
            embed_links: true
          ),
          footer: render(Primer::Beta::Text.new(color: :muted)) { I18n.t("attribute_help_texts.note_public") }
        }
      )

      attribute_form.submit(
        name: :submit,
        label: I18n.t(:button_save),
        scheme: :primary
      )
    end

    def initialize(hide_attribute_name: false)
      super()

      @hide_attribute_name = hide_attribute_name
    end

    def hide_attribute_name? = @hide_attribute_name

    private

    def selectable_attributes
      @selectable_attributes ||= begin
        available = model.class.available_attributes
        used = AttributeHelpText.used_attributes(model.type)

        # Always include the current attribute_name if it's set, even if it's "used"
        filtered = available.reject { |key,| used.include?(key) && key != model.attribute_name }

        filtered
          .map { |key, label| [label, key] }
          .sort_by { |label, _key| label.downcase }
      end
    end
  end
end
