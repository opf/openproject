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

require "rails_helper"

# Regression spec for AGILE-306: non-admin users could not group by backlog bucket when
# project-based semantic identifiers (Beta) were enabled.
#
# Root cause: the backlog bucket join SQL embeds a subquery containing
# `INNER JOIN "projects" ON` for permission checks (non-admin path). Rails's
# AliasTracker scanned that raw string and aliased the projects association as
# "projects_work_packages". OpenProject's include_aliases didn't mirror this
# pre-count, so the ORDER BY still referenced "projects.identifier" (the
# semantic-id tiebreaker) instead of "projects_work_packages.identifier",
# causing a PG::UndefinedTable error.
RSpec.describe Query::Results, "group by bucket" do # rubocop:disable RSpec/SpecFilePathFormat
  shared_let(:project) do
    create(:project, enabled_module_names: %i[work_package_tracking backlogs])
  end
  shared_let(:bucket) { create(:backlog_bucket, project:, name: "My Bucket") }
  shared_let(:work_package) { create(:work_package, project:, backlog_bucket: bucket) }

  let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_work_packages view_sprints] })
  end
  let(:query) do
    build(:query,
          user:,
          project:,
          show_hierarchies: false,
          group_by: "backlog_bucket",
          column_names: %i[id subject backlog_bucket])
  end

  current_user { user }

  context "with semantic identifiers enabled",
          with_settings: { work_packages_identifier: "semantic" } do
    it "does not raise a SQL error (Regression AGILE-306)" do
      expect { described_class.new(query).work_packages.to_a }.not_to raise_error
    end

    it "returns the work package" do
      expect(described_class.new(query).work_packages).to include(work_package)
    end
  end

  context "with classic identifiers enabled",
          with_settings: { work_packages_identifier: "classic" } do
    it "does not raise a SQL error" do
      expect { described_class.new(query).work_packages.to_a }.not_to raise_error
    end
  end
end
