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

# Lifts the inline user filters of the existing generic allocations into
# placeholder users and links the allocations to them.
#
# Allocations asking for the same filter are merged into one placeholder even
# when they were labelled differently.
class BackfillPlaceholderUsersFromAllocations < ActiveRecord::Migration[8.1]
  ACTIVE_STATUS = 1 # Principal.statuses[:active]

  # Filters are ANDed and their values are a set, so neither order carries
  # meaning — but jsonb compares arrays positionally. Allocations are therefore
  # grouped and matched on this canonical form rather than the raw column.
  CANONICAL_FILTER = <<~SQL.squish
    (SELECT COALESCE(jsonb_agg(
              jsonb_build_object(
                'attribute', element->>'attribute',
                'operator', element->>'operator',
                'values', COALESCE((SELECT jsonb_agg(value ORDER BY value)
                                    FROM jsonb_array_elements(element->'values') value), '[]'::jsonb)
              )
              ORDER BY element->>'attribute', element->>'operator'
            ), '[]'::jsonb)
     FROM jsonb_array_elements(user_filter) element)
  SQL

  def up
    taken_names = select_values("SELECT lastname FROM users WHERE type = 'PlaceholderUser'").to_set

    merged_requests.each do |request|
      name = unique_name(request["base_name"], taken_names)
      taken_names << name

      principal_id = create_placeholder_user(name, request["user_filter"])
      link_allocations(principal_id, request["canonical_filter"])
    end
  end

  # Only the placeholders this migration created carry a filter, so those are
  # the ones it removes again.
  def down
    execute "UPDATE resource_allocations SET placeholder_user_id = NULL"

    ids = select_values("SELECT principal_id FROM placeholder_user_details WHERE user_filter <> '[]'::jsonb")
    return if ids.empty?

    execute "DELETE FROM placeholder_user_details WHERE principal_id IN (#{ids.join(',')})"
    execute "DELETE FROM users WHERE id IN (#{ids.join(',')})"
  end

  private

  # One placeholder per distinct filter. Where the merged allocations disagree
  # on the label, the most used one wins (alphabetical on a tie, so that
  # repeated runs on the same data produce the same names). Allocations
  # predating `filter_name` have none and fall back to a shared label; names are
  # truncated to leave room for the " (2)" suffix within the 256 character limit.
  #
  # The filter stored on the placeholder is taken verbatim from one of the
  # merged allocations, so the criteria read back exactly as they were entered.
  def merged_requests
    select_all(<<~SQL.squish)
      WITH requests AS (
        SELECT id,
               #{CANONICAL_FILTER} AS canonical_filter,
               LEFT(COALESCE(NULLIF(filter_name, ''), 'Resource request'), 250) AS base_name
        FROM resource_allocations
        WHERE principal_explicit = false
          AND user_filter IS NOT NULL
          AND user_filter <> '[]'::jsonb
      ), labelled AS (
        SELECT canonical_filter,
               base_name,
               COUNT(*) AS usages,
               MIN(id) AS representative_id
        FROM requests
        GROUP BY canonical_filter, base_name
      ), ranked AS (
        SELECT canonical_filter,
               base_name,
               representative_id,
               ROW_NUMBER() OVER (PARTITION BY canonical_filter ORDER BY usages DESC, base_name ASC) AS name_rank,
               SUM(usages) OVER (PARTITION BY canonical_filter) AS total_usages
        FROM labelled
      )
      SELECT ranked.canonical_filter,
             ranked.base_name,
             allocations.user_filter
      FROM ranked
      JOIN resource_allocations allocations ON allocations.id = ranked.representative_id
      WHERE ranked.name_rank = 1
      ORDER BY ranked.base_name, ranked.total_usages DESC, ranked.canonical_filter
    SQL
  end

  def unique_name(base_name, taken_names)
    return base_name unless taken_names.include?(base_name)

    suffix = 2
    suffix += 1 while taken_names.include?("#{base_name} (#{suffix})")
    "#{base_name} (#{suffix})"
  end

  def create_placeholder_user(name, user_filter)
    principal_id = select_value(<<~SQL.squish)
      INSERT INTO users (type, lastname, status, created_at, updated_at)
      VALUES ('PlaceholderUser', #{quote(name)}, #{ACTIVE_STATUS}, NOW(), NOW())
      RETURNING id
    SQL

    execute(<<~SQL.squish)
      INSERT INTO placeholder_user_details (principal_id, user_filter, created_at, updated_at)
      VALUES (#{principal_id}, #{quote(user_filter)}::jsonb, NOW(), NOW())
    SQL

    principal_id
  end

  # `principal_id` is left alone: a staffed allocation keeps its user and gains
  # the placeholder it was originally requested as.
  def link_allocations(principal_id, canonical_filter)
    execute(<<~SQL.squish)
      UPDATE resource_allocations
      SET placeholder_user_id = #{principal_id}
      WHERE principal_explicit = false
        AND user_filter IS NOT NULL
        AND #{CANONICAL_FILTER} = #{quote(canonical_filter)}::jsonb
    SQL
  end
end
