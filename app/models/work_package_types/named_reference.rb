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
  module NamedReference
    extend ActiveSupport::Concern

    included do
      validates :name, presence: true, length: { maximum: 255 }
      validates :description, length: { maximum: 255 }

      scope :in_display_order, -> {
        (defaultable? ? order(is_default: :desc) : all).order(Arel.sql("LOWER(name) ASC"))
      }

      scope :with_name_like, ->(query) {
        where("name ILIKE :query", query: "%#{sanitize_sql_like(query.to_s.strip)}%")
      }
    end

    class_methods do
      def defaultable? = column_names.include?("is_default")

      def variant_reflection = reflect_on_association(:type_variants).inverse_of

      def implicit_name(source)
        base = source.to_s.strip.presence
        available_name(base && I18n.t("name.implicit", scope: model_name.plural, name: base))
      end

      def available_name(base)
        base = base.to_s.strip.presence || I18n.t("name.fallback", scope: model_name.plural)
        return base unless exists?(["LOWER(name) = LOWER(?)", base])

        suffix = 2
        suffix += 1 while exists?(["LOWER(name) = LOWER(?)", "#{base} (#{suffix})"])
        "#{base} (#{suffix})"
      end
    end

    def marked_default? = self.class.defaultable? && is_default?

    def used_by_one_variant?
      type_variants.one?
    end
  end
end
