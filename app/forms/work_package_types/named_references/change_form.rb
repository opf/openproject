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

module WorkPackageTypes
  module NamedReferences
    class ChangeForm < ApplicationForm
      include Translatable
      include ActionView::RecordIdentifier

      def initialize(variant:, model_class:)
        super()

        @variant = variant
        @model_class = model_class
      end

      form do |change_form|
        change_form.autocompleter(
          name: model_class.variant_reflection.foreign_key,
          label: reference_translate("change.select.label"),
          caption: reference_translate("change.select.caption"),
          required: true,
          autocomplete_options: {
            placeholder: reference_translate("change.select.placeholder"),
            decorated: true,
            multiple: false,
            focusDirectly: false,
            append_to: "##{ChangeDialogComponent.dialog_id(model_class)}",
            data: { test_selector: "change-#{dom_class(model_class)}-select" }
          }
        ) do |list|
          candidates.each do |candidate|
            list.option(value: candidate.id, label: candidate.name, selected: candidate.id == current_id)
          end
        end
      end

      private

      attr_reader :variant, :model_class

      def current_id = variant[model_class.variant_reflection.foreign_key]

      def candidates = @candidates ||= model_class.available_in(variant.project).in_display_order.to_a
    end
  end
end
