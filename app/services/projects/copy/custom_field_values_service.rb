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

module Projects::Copy
  # The result maps the ids of the copied values as { custom_field_id => { "source value id" => "copied value id" } },
  # with the ids as strings, as custom values store them.
  class CustomFieldValuesService < ::BaseServices::BaseCallable
    def initialize(source:, target:)
      super()
      @source = source
      @target = target
    end

    def perform
      copy_restrictions

      ServiceResult.success(result: copy_options.merge(copy_items))
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure(errors: e.record.errors)
    end

    private

    attr_reader :source, :target

    def copy_restrictions
      rows = source.custom_field_value_restrictions.map do |restriction|
        restriction.slice(:custom_field_id, :restriction, :custom_option_id, :hierarchy_item_id).merge(project_id: target.id)
      end

      CustomField::ProjectSpecificValueRestriction.insert_all(rows) if rows.any?
    end

    def copy_options
      CustomOption.where(project: source).order(:custom_field_id, :position).each_with_object({}) do |option, lookup|
        copy = copy_option(option)

        lookup[option.custom_field_id] ||= {}
        lookup[option.custom_field_id][option.id.to_s] = copy.id.to_s
      end
    end

    def copy_option(option)
      next_position = CustomOption.where(custom_field_id: option.custom_field_id).maximum(:position).to_i + 1

      CustomOption.create!(custom_field_id: option.custom_field_id, value: option.value, project: target, position: next_position)
    end

    def copy_items
      copies = copy_items_below_their_parents
      rebuild_position_caches(copies.values)

      copies.each_with_object({}) do |(source_id, copy), lookup|
        custom_field_id = copy.root.custom_field_id

        lookup[custom_field_id] ||= {}
        lookup[custom_field_id][source_id.to_s] = copy.id.to_s
      end
    end

    # Ordered by their position, parents are copied before their children.
    def copy_items_below_their_parents
      items = CustomField::Hierarchy::Item.where(project: source).order(:position_cache).includes(:parent)

      items.each_with_object({}) do |item, copies|
        copies[item.id] = copy_item(item, copies[item.parent_id] || item.parent)
      end
    end

    def copy_item(item, parent)
      copy = CustomField::Hierarchy::Item.new(label: item.label, short: item.short, weight: item.weight, project: target)
      copy.place_under(parent)
      raise ActiveRecord::RecordInvalid, copy unless copy.persisted?

      copy
    end

    def rebuild_position_caches(copies)
      copies.map(&:root).uniq.each do |root|
        CustomFields::Hierarchy::Items::RebuildPositionCacheService.new(user: User.system, model: root).call
      end
    end
  end
end
