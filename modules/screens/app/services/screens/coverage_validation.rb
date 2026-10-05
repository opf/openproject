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
# frozen_string_literal: true

module Screens
  # Two tiers, as designed in spec section 4:
  #   1. Cheap checks that can block a save: an in-use create screen must place subject.
  #   2. Checks that depend on F02 or on the projects using a scheme never block; they are warnings.
  class CoverageValidation
    Result = Data.define(:errors, :warnings)

    class << self
      def screen(screen)
        return Result.new(errors: [], warnings: []) unless screen.create?

        live_items = screen.items.reject(&:marked_for_destruction?)
        subject_visible = live_items.any? { |item| item.field_key == "subject" && item.visible }
        if screen.in_use?
          Result.new(errors: subject_visible ? [] : [:required_not_placed], warnings: [])
        else
          warnings = []
          warnings << :empty_create_screen if live_items.empty?
          warnings << :required_not_placed unless subject_visible
          Result.new(errors: [], warnings:)
        end
      end

      # Tier 1.2: placing a create screen on a scheme row requires the type's required fields to be
      # placed. It only covers the row's own type and is capped; above the cap it degrades to a
      # warning instead of blocking.
      def scheme_item(item)
        return Result.new(errors: [], warnings: []) if item.create_screen.nil?

        required = RequiredSet.for_scheme_type(item.scheme, item.type)
        return Result.new(errors: [], warnings: [:skipped_due_to_scale]) if required == :skipped

        errors = required.flat_map do |project_id, keys|
          keys.filter_map do |key|
            next if placed_visible?(item.create_screen, key)

            { field: key, type_id: item.type_id, project_id: }
          end
        end
        Result.new(errors: errors.first(10), warnings: errors.size > 10 ? [:more_required_not_placed] : [])
      end

      private

      def placed_visible?(screen, key)
        screen.items.any? { |item| item.field_key == key && item.visible }
      end
    end
  end
end
