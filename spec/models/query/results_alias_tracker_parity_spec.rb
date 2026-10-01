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

require "spec_helper"

# Guards against Query::Results::RAW_JOIN_TABLE_SCAN_REGEX drifting away from
# ActiveRecord::Associations::AliasTracker.initial_count_for's scan pattern.
#
# AliasTracker is a private Rails API that counts how many times a table name
# appears as a JOIN target in raw SQL strings. Query::Results#raw_join_table_counts
# mirrors this counting so that include_aliases computes the same aliases Rails
# will actually use. If Rails changes their regex, this spec fails and tells us
# to update RAW_JOIN_TABLE_SCAN_REGEX accordingly.
RSpec.describe Query::Results, "RAW_JOIN_TABLE_SCAN_REGEX parity with AliasTracker" do
  let(:connection) { ActiveRecord::Base.connection }

  def alias_tracker_count(table_name, sql)
    node = Arel::Nodes::StringJoin.new(Arel.sql(sql))
    ActiveRecord::Associations::AliasTracker.initial_count_for(connection, table_name, [node])
  end

  def our_count(table_name, sql)
    sql.scan(described_class::RAW_JOIN_TABLE_SCAN_REGEX).count do |quoted, unquoted|
      (quoted || unquoted) == table_name
    end
  end

  # Each entry is [table_name, sql_string].
  # Cover the main patterns we encounter so a Rails regex change is caught early.
  cases = [
    # Direct quoted join — the standard Rails-generated form
    ["projects", 'INNER JOIN "projects" ON "projects"."id" = "members"."project_id"'],
    # Unquoted join
    ["projects", "INNER JOIN projects ON projects.id = work_packages.project_id"],
    # Left outer join
    ["projects", 'LEFT OUTER JOIN "projects" ON "projects"."id" = x.id'],
    # Different table
    ["enabled_modules", 'INNER JOIN "enabled_modules" ON "enabled_modules"."project_id" = "projects"."id"'],
    # Table referenced in ON clause only — should NOT be counted
    ["projects", 'INNER JOIN "enabled_modules" ON "enabled_modules"."project_id" = "projects"."id"'],
    # Nested subquery — mirrors the backlog bucket permission join for non-admin users,
    # where projects_with_view_sprints.to_sql embeds INNER JOIN "projects" ON inside a subquery.
    # AliasTracker scans the whole raw string and counts this even though it is nested.
    ["projects", <<~SQL.squish],
      LEFT OUTER JOIN (SELECT bb.* FROM backlog_buckets bb) AS visible_buckets
      ON visible_buckets.id = work_packages.backlog_bucket_id
      AND work_packages.project_id IN (
        SELECT "projects"."id" FROM "projects"
        INNER JOIN "members" ON "members"."project_id" = "projects"."id"
        INNER JOIN "member_roles" ON "member_roles"."member_id" = "members"."id"
        WHERE "members"."user_id" = 42
      )
    SQL
    # Admin permission path — joins enabled_modules, not projects; projects should be 0
    ["projects", <<~SQL.squish],
      INNER JOIN "enabled_modules"
      ON "enabled_modules"."project_id" = "projects"."id"
      AND "enabled_modules"."name" = 'backlogs'
    SQL
    # Multiple occurrences of the same table
    ["projects", 'INNER JOIN "projects" ON "projects"."id" = x.id LEFT OUTER JOIN "projects" ON "projects"."id" = y.id'],
    # Empty string
    ["projects", ""]
  ].freeze

  cases.each do |table_name, sql|
    it "counts #{table_name.inspect} identically to AliasTracker in: #{sql[0, 70]}#{'...' if sql.length > 70}" do
      expect(our_count(table_name, sql)).to eq(alias_tracker_count(table_name, sql))
    end
  end
end
