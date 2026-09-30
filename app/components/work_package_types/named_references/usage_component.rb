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
    class UsageComponent < ApplicationComponent
      include Translatable
      include OpPrimer::ComponentHelpers
      include WorkPackageTypes::VariantRoutes

      def initialize(record:, model_class:, list_users: true)
        super()

        @record = record
        @model_class = model_class
        @list_users = list_users
      end

      private

      attr_reader :record, :model_class

      def variants
        @variants ||= record.type_variants.includes(:type).in_display_order
      end

      def unused? = variants.empty?

      def list_users? = @list_users && !unused?

      def variants_only? = variants.any? { !it.is_default_variant? }

      def caption
        return reference_translate("usage.unused") if unused?
        return reference_translate("usage.used_by_variants", count: variants.size) if variants_only?

        reference_translate("usage.used_by_types", count: variants.size)
      end

      def types = variants.select(&:is_default_variant?)

      def named_variants = variants.reject(&:is_default_variant?)

      def banner_scheme = unused? ? :default : :warning

      def dialog_id = "#{dom_class(model_class)}-usage-dialog"

      def test_selector(part) = "#{dom_class(model_class)}-usage-#{part}"

      def dialog_caption
        reference_translate("usage.dialog.caption_html", name: content_tag(:strong, record.name))
      end

      def variant_link(variant)
        href = variant_reference_path(nil, variant, model_class, action: :edit)

        render(Primer::Beta::Link.new(href:)) { variant.display_name }
      end
    end
  end
end
