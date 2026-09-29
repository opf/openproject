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
    class NameForm < ApplicationForm
      def initialize(model_class:, copy_from_id: nil, ask_copy_source: true)
        super()

        @model_class = model_class
        @copy_from_id = copy_from_id
        @ask_copy_source = ask_copy_source
      end

      form do |name_form|
        name_form.text_field(name: :name,
                             label: model_class.reference_t("form.name.label"),
                             caption: model_class.reference_t("form.name.caption"),
                             required: true,
                             autofocus: true)

        name_form.text_area(name: :description,
                            rows: 3,
                            label: model_class.reference_t("form.description.label"),
                            caption: model_class.reference_t("form.description.caption"))

        next if model.persisted?

        if copy_from_id.present?
          name_form.hidden(name: :copy_from_id, value: copy_from_id)
          next
        end

        next if !ask_copy_source || copy_sources.empty?

        name_form.autocompleter(
          name: :copy_from_id,
          label: model_class.reference_t("form.copy_from.label"),
          caption: model_class.reference_t("form.copy_from.caption"),
          autocomplete_options: {
            placeholder: model_class.reference_t("form.copy_from.placeholder"),
            decorated: true,
            multiple: false,
            focusDirectly: false,
            append_to: "##{NameFormComponent.dialog_id(model_class)}",
            data: { test_selector: "#{model_class.reference_dom_key}-copy-from" }
          }
        ) do |list|
          copy_sources.each { |source| list.option(value: source.id, label: source.name) }
        end
      end

      private

      attr_reader :model_class, :copy_from_id, :ask_copy_source

      def copy_sources
        @copy_sources ||= model_class.available_in(model.try(:project)).in_display_order.to_a
      end
    end
  end
end
