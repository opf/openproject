# frozen_string_literal: true

# -- copyright
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
# ++
require "spec_helper"

# Wraps the real spent-time query (joins + an existing WITH + grouping) in a
# CteCollector to check the permission derivation hoists into a shared CTE without
# changing the summed hours.
RSpec.describe "shared_user_permissions_cte on the spent-time query", :aggregate_failures do # rubocop:disable RSpec/DescribeClass
  shared_let(:project) { create(:project) }
  shared_let(:role) { create(:project_role, permissions: %i[view_time_entries view_work_packages]) }
  shared_let(:user) { create(:user, member_with_roles: { project => role }) }

  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:child) { create(:work_package, project:, parent: work_package) }
  shared_let(:self_time_entry) { create(:time_entry, entity: work_package, project:, hours: 2.0) }
  shared_let(:child_time_entry) { create(:time_entry, entity: child, project:, hours: 3.0) }

  def spent_time_by_id(relation)
    relation.to_a.to_h { |wp| [wp.id, wp.hours.to_f] }
  end

  # include_spent_time selects only the summed hours; callers add the id (see
  # WorkPackageEagerLoadingWrapper#spent_time_subquery), so mirror that here. This is
  # the final relation a collector must wrap (wrapping before the id is selected would
  # hide it behind the FROM-subquery).
  def spent_time_relation
    WorkPackage.include_spent_time(user).select(:id)
  end

  def collector_for(relation)
    OpenProject::ActiveRecordExtensions::CteCollector.new(relation:)
  end

  it "returns the same spent-time sums collapsed as uncollapsed" do
    with_flags(shared_user_permissions_cte: false)
    legacy = spent_time_by_id(spent_time_relation)

    with_flags(shared_user_permissions_cte: true)
    collapsed = spent_time_by_id(collector_for(spent_time_relation))

    expect(collapsed).to eq(legacy)
    expect(legacy.keys).to include(work_package.id, child.id)
    expect(legacy.values.sum).to be > 0
  end

  it "returns the same TimeEntry.visible ids under both flag states" do
    with_flags(shared_user_permissions_cte: false)
    legacy = TimeEntry.visible(user).order(:id).ids

    with_flags(shared_user_permissions_cte: true)
    cte = TimeEntry.visible(user).order(:id).ids

    expect(cte).to eq(legacy)
    expect(legacy).to include(self_time_entry.id, child_time_entry.id)
  end

  it "hoists the permission derivation into a shared CTE while keeping the visible_time_entries CTE" do
    with_flags(shared_user_permissions_cte: true)
    sql = collector_for(spent_time_relation).to_sql

    expect(sql.scan(/user_permissions_\h+" AS/).size).to be >= 1
    expect(sql).to include("visible_time_entries")
  end

  it "computes the same per-work-package spent hours collapsed as uncollapsed" do
    # A freshly loaded record has no eager-loaded #hours, so #spent_hours falls back to
    # compute_spent_hours, which the collector now wraps when the flag is on.
    with_flags(shared_user_permissions_cte: false)
    legacy = WorkPackage.find(work_package.id).spent_hours(user)

    with_flags(shared_user_permissions_cte: true)
    collapsed = WorkPackage.find(work_package.id).spent_hours(user)

    expect(collapsed).to eq(legacy)
    expect(legacy).to eq(5.0)
  end

  it "embeds as a subquery the way the eager-loading wrapper does" do
    with_flags(shared_user_permissions_cte: true)
    time_scope = collector_for(spent_time_relation)

    # Mirror WorkPackageEagerLoadingWrapper#spent_time_subquery.
    wp_table = WorkPackage.arel_table
    alias_table = Arel::Table.new("spent_time_hours")
    join = wp_table
             .outer_join(time_scope.arel.as("spent_time_hours"))
             .on(wp_table[:id].eq(alias_table[:id]))

    expect { WorkPackage.joins(join.join_sources).limit(1).to_a }.not_to raise_error
  end

  # Pins the material (CostEntry) and labor (TimeEntry) cost-column sums the eager-loading
  # wrapper adds, since the cost visibility nests Project.allowed_to several more times.
  # Self-contained fixtures (costs module enabled, full cost/rate permissions).
  context "on the cost columns" do
    shared_let(:cost_project) { create(:project, enabled_module_names: %w[work_package_tracking costs]) }
    shared_let(:cost_role) do
      create(:project_role,
             permissions: %i[view_work_packages view_time_entries view_own_time_entries
                             view_cost_entries view_own_cost_entries view_cost_rates
                             view_hourly_rates view_own_hourly_rate])
    end
    shared_let(:cost_user) { create(:user, member_with_roles: { cost_project => cost_role }) }
    shared_let(:cost_wp) { create(:work_package, project: cost_project) }
    shared_let(:cost_entry) do
      create(:cost_entry, entity: cost_wp, project: cost_project, user: cost_user, overridden_costs: 12.0)
    end
    shared_let(:cost_time_entry) do
      create(:time_entry, entity: cost_wp, project: cost_project, user: cost_user, hours: 4.0, overridden_costs: 7.0)
    end

    # Mirror WorkPackageEagerLoadingWrapper: assemble the material + labor cost joins,
    # then collapse via CteCollector.collect when the flag is on.
    def cost_sums
      login_as(cost_user)
      scope = WorkPackage.where(id: cost_wp.id)
      material = WorkPackage::MaterialCosts.new(user: cost_user).add_to_work_package_collection(scope.dup)
      labor = WorkPackage::LaborCosts.new(user: cost_user).add_to_work_package_collection(scope.dup)

      assembled = scope
                    .joins(material.arel.join_sources)
                    .joins(labor.arel.join_sources)
                    .select("work_packages.id", material.select_values, labor.select_values)

      OpenProject::ActiveRecordExtensions::CteCollector
        .collect(assembled)
        .to_a
        .to_h { |wp| [wp.id, [wp["cost_entries_sum"].to_f, wp["time_entries_sum"].to_f]] }
    end

    it "computes the same material and labor cost sums collapsed as uncollapsed" do
      with_flags(shared_user_permissions_cte: false)
      legacy = cost_sums

      with_flags(shared_user_permissions_cte: true)
      collapsed = cost_sums

      expect(collapsed).to eq(legacy)
      expect(legacy[cost_wp.id]).to eq([12.0, 7.0])
    end
  end
end
