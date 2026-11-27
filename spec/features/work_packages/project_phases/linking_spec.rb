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

require "spec_helper"

RSpec.describe "Linking projects phases and work packages", :js do
  shared_let(:initiating_phase_definition) { create(:project_phase_definition, name: "Initiating") }
  shared_let(:executing_phase_definition) do
    create(:project_phase_definition, name: "Executing", start_gate: true, start_gate_name: "Ready to Execute")
  end
  shared_let(:project) { create(:project) }
  shared_let(:initiating_phase) { create(:project_phase, project: project, definition: initiating_phase_definition) }
  shared_let(:executing_phase) { create(:project_phase, project: project, definition: executing_phase_definition) }
  shared_let(:work_package) do
    create(:work_package,
           project:,
           project_phase_definition: executing_phase_definition)
  end
  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_project_phases view_work_packages edit_work_packages] })
  end
  current_user { user }

  let(:work_package_page) { Pages::FullWorkPackage.new(work_package) }
  let(:activity_tab) { Components::WorkPackages::Activities.new(work_package) }

  it "allows seeing and editing linked phases" do
    work_package_page.visit!

    work_package_page.expect_attributes(project_phase: executing_phase_definition.name)

    work_package_page.set_attributes({ projectPhase: initiating_phase_definition.name })

    activity_tab.within_journal_entry(work_package.journals.last) do
      activity_tab.expect_journal_changed_attribute(
        text: "Project phase changed from #{executing_phase_definition.name} to #{initiating_phase_definition.name}"
      )
    end

    work_package_page.expect_and_dismiss_toaster(message: "Successful update.")

    work_package_page.expect_attributes(project_phase: initiating_phase_definition.name)
  end
end
