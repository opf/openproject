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
  module ConfigurationLinks
    class SourceForm < ApplicationForm
      include WorkPackageTypes::SourceOptions

      def initialize(variant:, aspect:)
        super()

        @variant = variant
        @aspect = aspect
      end

      form do |source_form|
        source_form.autocompleter(
          name: :source_id,
          label: I18n.t("types.edit.reuse_mode.inherited.dialog.source_label"),
          required: true,
          autocomplete_options: {
            placeholder: I18n.t("types.edit.reuse_mode.inherited.dialog.source_placeholder"),
            decorated: true,
            multiple: false,
            focusDirectly: false,
            append_to: "##{DialogComponent::DIALOG_ID}",
            data: { test_selector: "configuration-link-source" }
          }
        ) do |list|
          source_options.each do |source|
            list.option(value: source.id, label: label_for(source), selected: source == selected_source)
          end
        end
      end

      private

      attr_reader :variant, :aspect

      def selected_source
        current = variant.source_for(aspect)
        return current if current

        base = variant.type.default_variant
        base unless base == variant
      end
    end
  end
end
