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

RSpec.describe WorkPackages::Scopes::WithoutStatusConsideredClosed do
  let(:user) { create(:admin) }
  let(:open_status) { create(:status, is_closed: false) }
  let(:closed_status) { create(:status, is_closed: true) }
  let(:open_status_defined_as_done_in_project) { create(:status, is_closed: false) }
  let(:project) do
    create(:project, enabled_module_names: %w[backlogs]) do |p|
      p.done_status_ids = [closed_status.id, open_status_defined_as_done_in_project.id]
    end
  end

  current_user { user }

  subject(:unfinished) { WorkPackage.without_status_considered_closed }

  describe ".without_status_considered_closed" do
    it "returns work packages that are defined as 'not done' in the project" do
      wp_with_open_status = create(:work_package, project:, status: open_status)
      create(:work_package, project:, status: closed_status)
      create(:work_package, project:, status: open_status_defined_as_done_in_project)

      expect(unfinished).to contain_exactly(wp_with_open_status)
    end

    it "treats globally closed statuses as done when project config is empty (corruption case)" do
      # Safeguard: even if a project's done_statuses_for_project is empty (corruption),
      # any status with is_closed: true should still be treated as done.
      project_with_empty_config = create(:project, enabled_module_names: %w[backlogs]) do |p|
        # Deliberately empty done_status_ids to simulate corruption
        p.done_status_ids = []
      end

      # WP with a globally closed status in the corrupted project
      create(:work_package, subject: "Corrupted wp", status: closed_status, project: project_with_empty_config)

      # WP with an open status in the corrupted project
      open_wp = create(:work_package, status: open_status, project: project_with_empty_config)

      expect(unfinished).to contain_exactly(open_wp)
    end

    it "respects per-project status configuration" do
      # A status that is globally open (is_closed: false) but configured as done in one project
      # and not in another
      globally_open_status = create(:status, is_closed: false)

      project_where_status_is_done = create(:project, enabled_module_names: %w[backlogs]) do |p|
        p.done_status_ids = [globally_open_status.id]
      end

      project_where_status_is_not_done = create(:project, enabled_module_names: %w[backlogs]) do |p|
        p.done_status_ids = []
      end

      # WP in project A with the status → should NOT be unfinished (configured as done)
      create(:work_package, subject: "wp in project a", status: globally_open_status, project: project_where_status_is_done)

      # WP in project B with the status → should be unfinished (not configured as done)
      wp_in_project_b = create(:work_package, status: globally_open_status, project: project_where_status_is_not_done)

      expect(unfinished).to contain_exactly(wp_in_project_b)
    end
  end
end
