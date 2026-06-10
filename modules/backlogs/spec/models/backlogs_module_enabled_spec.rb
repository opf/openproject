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

RSpec.describe "Backlogs MODULE_ENABLED event" do # rubocop:disable RSpec/DescribeClass
  let!(:closed_status1) { create(:status, is_closed: true) }
  let!(:closed_status2) { create(:status, is_closed: true) }
  let!(:open_status) { create(:status, is_closed: false) }

  describe "seeding done_statuses on backlogs module enable" do
    context "when the backlogs module is enabled on a project" do
      it "seeds all is_closed statuses as done_statuses for the project" do
        project = create(:project, enabled_module_names: %w[backlogs work_package_tracking])

        expect(project.done_statuses).to contain_exactly(closed_status1, closed_status2)
      end

      it "does not add non-closed statuses as done_statuses" do
        project = create(:project, enabled_module_names: %w[backlogs work_package_tracking])

        expect(project.done_statuses).not_to include(open_status)
      end

      it "does not cause duplicate entries when some closed statuses are already present" do
        # Create the project without backlogs first, then manually add a closed status,
        # then enable the module to simulate partial pre-existing configuration.
        project = create(:project, enabled_module_names: %w[work_package_tracking])
        project.done_statuses << closed_status1

        expect { project.enabled_modules.create!(name: "backlogs") }
          .not_to raise_error

        project.reload
        # closed_status1 should appear exactly once, closed_status2 should now also be present
        expect(project.done_statuses.where(id: closed_status1.id).count).to eq(1)
        expect(project.done_statuses).to include(closed_status2)
      end
    end

    context "when a non-backlogs module is enabled" do
      it "does not touch done_statuses" do
        project = create(:project, enabled_module_names: %w[work_package_tracking])

        expect(project.done_statuses).to be_empty
      end
    end

    context "when there are no closed statuses in the system" do
      before { Status.where(is_closed: true).delete_all }

      it "does not raise and leaves done_statuses empty" do
        expect { create(:project, enabled_module_names: %w[backlogs work_package_tracking]) }
          .not_to raise_error
      end
    end

    context "when backlogs module is enabled a second time (re-enabled)" do
      it "does not duplicate already-present done_statuses" do
        project = create(:project, enabled_module_names: %w[backlogs work_package_tracking])
        initial_done_status_ids = project.done_statuses.pluck(:id).sort

        # Disable and re-enable
        project.enabled_module_names = %w[work_package_tracking]
        project.enabled_module_names = %w[backlogs work_package_tracking]
        project.reload

        expect(project.done_statuses.pluck(:id).sort).to eq(initial_done_status_ids)
      end
    end
  end
end
