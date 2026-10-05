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
  # Cleans up data the resolver already ignores: items pointing at deleted custom fields and
  # position gaps. Safe to run repeatedly.
  class Repair
    Report = Struct.new(:orphan_items, :renumbered_screens, :dry_run, keyword_init: true)

    def self.call(dry_run: true) = new(dry_run:).call

    def initialize(dry_run:)
      @dry_run = dry_run
    end

    def call
      orphans = orphan_items
      screens = screens_with_gaps
      apply(orphans, screens) unless @dry_run
      Resolver.reset_cache
      Report.new(orphan_items: orphans.size, renumbered_screens: screens.size, dry_run: @dry_run)
    end

    private

    def orphan_items
      existing = WorkPackageCustomField.pluck(:id).to_set
      ScreenItem.where("field_key LIKE 'custom_field_%'").select do |item|
        id = Fields.custom_field_id(item.field_key)
        id.nil? || existing.exclude?(id)
      end
    end

    def screens_with_gaps
      Screen.includes(sections: :items).select { |screen| gaps?(screen) }
    end

    def gaps?(screen)
      screen.sections.each_with_index.any? { |section, index| section.position.to_i != index + 1 } ||
        screen.sections.any? do |section|
          section.items.sort_by { |item| [item.position.to_i, item.id.to_i] }
                 .each_with_index.any? { |item, index| item.position.to_i != index + 1 }
        end
    end

    def apply(orphans, screens)
      Screen.transaction do
        ScreenItem.where(id: orphans.map(&:id)).delete_all
        screens.each { |screen| renumber(screen) }
      end
    end

    def renumber(screen)
      screen.sections.order(:position, :id).each_with_index do |section, index|
        section.update_columns(position: index + 1)
        section.items.order(:position, :id).each_with_index do |item, item_index|
          item.update_columns(position: item_index + 1)
        end
      end
    end
  end
end
