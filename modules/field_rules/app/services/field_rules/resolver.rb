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

module FieldRules
  module Resolver
    CACHE_KEY = :field_rules_by_project_and_type

    module_function

    def for(project, type)
      project_id = id_of(project)
      type_id = id_of(type)
      return EffectiveConfiguration.empty if project_id.nil? || type_id.nil?

      cache = RequestStore.store[CACHE_KEY] ||= {}
      cache.fetch([project_id, type_id]) { cache[[project_id, type_id]] = load_one(project_id, type_id) }
    rescue StandardError => e
      Rails.logger.error("[field_rules] resolving rules failed, using native behaviour: #{e.class}: #{e.message}")
      EffectiveConfiguration.empty
    end

    # Preloads many (project, type) pairs with a single query to avoid N+1 in lists, exports and bulk operations.
    def for_many(project_ids, type_ids)
      project_ids = Array(project_ids).compact.uniq
      type_ids = Array(type_ids).compact.uniq
      cache = RequestStore.store[CACHE_KEY] ||= {}
      all_pairs = project_ids.product(type_ids)
      missing = all_pairs.reject { |pair| cache.key?(pair) }
      if missing.any?
        grouped = load_rules(project_ids, type_ids).group_by do |rule|
          [rule.attributes["fr_project_id"], rule.attributes["fr_type_id"]]
        end
        missing.each { |pair| cache[pair] = EffectiveConfiguration.from_rules(grouped.fetch(pair, [])) }
      end
      all_pairs.to_h { |pair| [pair, cache[pair]] }
    end

    def editable?(project, type, field_key)
      self.for(project, type).editable?(field_key)
    end

    def reset_cache
      RequestStore.store.delete(CACHE_KEY)
    end

    def system_actor?(user)
      user.nil? || user.is_a?(SystemUser)
    end

    def load_one(project_id, type_id)
      EffectiveConfiguration.from_rules(load_rules([project_id], [type_id]))
    end

    def load_rules(project_ids, type_ids)
      FieldRule
        .joins(rule_set: { scheme_items: { scheme: :project_assignments } })
        .where(field_rule_sets: { active: true },
               field_rule_schemes: { active: true },
               field_rule_scheme_items: { type_id: type_ids },
               project_field_rule_schemes: { project_id: project_ids })
        .select("field_rules.*",
                "project_field_rule_schemes.project_id AS fr_project_id",
                "field_rule_scheme_items.type_id AS fr_type_id")
        .order(:position, :id)
        .to_a
    end

    def id_of(record)
      record.respond_to?(:id) ? record.id : record
    end
  end
end
