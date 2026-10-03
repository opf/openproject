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

# Grouping or sorting by backlog bucket adds a raw SQL join whose permission
# subquery mentions the projects table. That mention must not stop the
# associations of other sort columns (e.g. category) from being joined, or
# their ORDER BY expressions reference tables missing from the query.
RSpec.describe Query::Results, "sorting by backlog bucket and an association column" do
  shared_let(:project) do
    create(:project, enabled_module_names: %w[work_package_tracking backlogs])
  end
  shared_let(:role) do
    create(:project_role, permissions: %i[view_work_packages view_sprints])
  end
  shared_let(:user) { create(:user, member_with_roles: { project => role }) }
  shared_let(:bucket) { create(:backlog_bucket, project:) }
  shared_let(:category) { create(:category, project:) }
  shared_let(:work_package) do
    create(:work_package, project:, backlog_bucket: bucket, category:, estimated_hours: 5)
  end

  let(:query) do
    build(:query, project: nil, user:).tap do |q|
      q.group_by = "backlog_bucket"
      q.sort_criteria = [%w[category asc]]
      q.column_names = %i[id subject estimated_hours]
      q.display_sums = true
    end
  end
  let(:results) { described_class.new(query) }

  current_user { user }

  it "lists the work packages" do
    expect(results.work_packages.to_a).to eq [work_package]
  end

  it "counts by group" do
    expect(results.work_package_count_by_group).to eq(bucket => 1)
  end

  it "computes total sums" do
    expect(results.all_total_sums.values).to include(5.0)
  end

  it "computes group sums" do
    expect(results.all_group_sums).to be_present
  end
end
