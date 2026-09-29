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
    class CopySourceForm < ApplicationForm
      include ActionView::RecordIdentifier

      def initialize(model_class:, candidates:, selected:, type_record_id: nil)
        super()

        @model_class = model_class
        @candidates = candidates
        @selected = selected
        @type_record_id = type_record_id
      end

      form do |source_form|
        source_form.autocompleter(
          name: :copy_from_id,
          label: model_class.reference_t("start.copy.panel_label"),
          visually_hide_label: true,
          required: true,
          autocomplete_options: {
            placeholder: model_class.reference_t("form.copy_from.placeholder"),
            decorated: true,
            multiple: false,
            focusDirectly: false,
            append_to: "##{NameFormComponent.dialog_id(model_class)}",
            data: { test_selector: "#{dom_class(model_class)}-copy-source" }
          }
        ) do |list|
          candidates.each do |candidate|
            list.option(value: candidate.id, label: label_for(candidate), selected: candidate.id == selected)
          end
        end
      end

      private

      attr_reader :model_class, :candidates, :selected, :type_record_id

      def label_for(candidate)
        return candidate.name unless candidate.id == type_record_id

        "#{candidate.name} #{model_class.reference_t('selector.same_as_type')}"
      end
    end
  end
end
