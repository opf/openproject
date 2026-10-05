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
  # Replaces the whole layout (sections and their items) of a screen in one transaction. Every
  # change takes the screen lock and re-checks the limits after the lock, so simultaneous requests
  # cannot exceed them.
  class LayoutService
    class << self
      def replace(screen, sections_params)
        result = nil
        Screen.transaction do
          screen.lock!
          result = apply(screen, normalize(sections_params))
          raise ActiveRecord::Rollback if result.failure?
        end
        result
      rescue ActiveRecord::RecordNotUnique
        screen.errors.add(:base, :conflict)
        fail_with(screen)
      end

      private

      def normalize(sections_params)
        Array(sections_params).map { |section| section.to_h.symbolize_keys }
      end

      def apply(screen, sections)
        errors = collect_errors(screen, sections)
        return failure(errors) if errors.any?

        sync_sections(screen, sections)
        coverage = coverage_errors(screen)
        return failure(coverage) if coverage.any?

        screen.save ? ok(screen) : fail_with(screen)
      end

      def coverage_errors(screen)
        return [] unless screen.persisted? && screen.in_use?

        CoverageValidation.screen(screen).errors
      end

      def collect_errors(screen, sections)
        errors = []
        errors << :too_many_sections if sections.size > Screen::MAX_SECTIONS
        items = sections.flat_map { |section| Array(section[:items]) }
        errors << :too_many_items if items.size > Screen::MAX_ITEMS
        errors << :duplicate_field unless items.map { |item| key_of(item) }.compact.uniq.size == items.count { |item| key_of(item) }
        items.each do |item|
          key = key_of(item)
          errors << :unknown_field unless key && ::Screens::Fields.placeable?(key)
          errors << :invalid_width if item[:width].present? && ScreenItem::WIDTHS.exclude?(item[:width].to_s)
        end
        errors.uniq
      end

      def sync_sections(screen, sections)
        wanted_sections = sections.index_by { |section| section[:id] }
        screen.sections.each { |section| section.mark_for_destruction unless wanted_sections.key?(section.id) }

        sections.each_with_index do |section_params, section_index|
          section = find_section(screen, section_params[:id]) || screen.sections.build
          section.name = section_params[:name].to_s
          section.position = section_index + 1
          sync_items(screen, section, Array(section_params[:items]))
        end
      end

      def sync_items(screen, section, items)
        wanted = items.index_by { |item| item[:id] }
        section.items.each { |item| item.mark_for_destruction unless wanted.key?(item.id) }

        items.each_with_index do |item_params, item_index|
          item = find_item(screen, item_params[:id]) || section.items.build
          item.field_key = key_of(item_params).to_s if key_of(item_params)
          item.screen = screen
          item.section = section
          item.position = item_index + 1
          item.width = item_params[:width].presence || item.width.presence || "full"
          item.visible = item_params.key?(:visible) ? ActiveModel::Type::Boolean.new.cast(item_params[:visible]) : item.visible
        end
      end

      def find_section(screen, id)
        return if id.blank?

        screen.sections.find { |section| section.id == id.to_i }
      end

      def find_item(screen, id)
        return if id.blank?

        screen.items.find { |item| item.id == id.to_i }
      end

      def key_of(item)
        value = item[:field_key] || item[:fieldKey]
        value&.to_s
      end

      def ok(result) = ServiceResult.success(result:)
      def fail_with(model) = ServiceResult.failure(result: model, errors: model.errors)

      def failure(codes)
        errors = ActiveModel::Errors.new(Screen.new)
        codes.each { |code| errors.add(:base, code) }
        ServiceResult.failure(errors:)
      end
    end
  end
end
