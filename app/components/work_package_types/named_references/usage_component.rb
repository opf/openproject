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
    class UsageComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      def initialize(record:, kind:, list_users: true)
        super()

        @record = record
        @kind = kind
        @list_users = list_users
      end

      private

      attr_reader :record, :kind

      def variants
        @variants ||= record.type_variants.includes(:type).in_display_order
      end

      def unused? = variants.empty?

      def list_users? = @list_users && !unused?

      def variants_only? = variants.any? { !it.is_default_variant? }

      def caption
        return kind.t("usage.unused") if unused?
        return kind.t("usage.used_by_variants", count: variants.size) if variants_only?

        kind.t("usage.used_by_types", count: variants.size)
      end

      def types = variants.select(&:is_default_variant?)

      def named_variants = variants.reject(&:is_default_variant?)

      def banner_scheme = unused? ? :default : :warning

      def dialog_id = "#{kind.dom_key}-usage-dialog"

      def test_selector(part) = "#{kind.dom_key}-usage-#{part}"

      def dialog_caption
        kind.t("usage.dialog.caption_html", name: content_tag(:strong, record.name))
      end

      def variant_link(variant)
        href = helpers.public_send(:"edit_type_#{kind.association}_path", **variant.path_args)

        render(Primer::Beta::Link.new(href:)) { variant.display_name }
      end
    end
  end
end
