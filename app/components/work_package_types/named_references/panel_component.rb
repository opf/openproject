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
    class PanelComponent < ApplicationComponent
      include Translatable
      include OpPrimer::ComponentHelpers
      include WorkPackageTypes::VariantRoutes

      def initialize(variant:, model_class:, candidates:, selected: nil, back_url: nil)
        super()

        @variant = variant
        @model_class = model_class
        @candidates = candidates
        @selected = selected
        @back_url = back_url
      end

      private

      attr_reader :variant, :model_class, :candidates, :back_url

      def record = variant.public_send(model_class.variant_reflection.name)

      def name = record.name

      def prefix = "#{reference_translate('selector.prefix')}:"

      def same_as_type_text = reference_translate("selector.same_as_type")

      def default_text = reference_translate("selector.default")

      def same_as_type? = variant.type_reference_id(model_class.variant_reflection) == record.id

      def selected = @selected || record.id

      def test_selector(part) = "#{dom_class(model_class)}-#{part}"

      def change_path(candidate)
        variant_reference_path(
          helpers.variant_scope_project, variant, model_class,
          action: :change,
          **{ model_class.variant_reflection.foreign_key => candidate.id, back_url: }.compact
        )
      end
    end
  end
end
