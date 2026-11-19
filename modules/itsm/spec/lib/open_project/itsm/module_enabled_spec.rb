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
require_module_spec_helper

RSpec.describe "Help desk MODULE_ENABLED event", with_flag: { helpdesk: true } do # rubocop:disable RSpec/DescribeClass
  let(:project) { create(:project, disable_modules: %i[helpdesk calendar_view]) }

  it "adds the help desk user to a project that enables the help desk" do
    project.enabled_modules.create!(name: "helpdesk")

    expect(Member.find_by(project:, principal: ITSM.helpdesk_user).roles).to contain_exactly(ITSM.helpdesk_role)
  end

  it "adds the help desk user to a project created with the help desk" do
    created = create(:project, enabled_module_names: %w[work_package_tracking helpdesk])

    expect(Member.find_by(project: created, principal: ITSM.helpdesk_user).roles).to contain_exactly(ITSM.helpdesk_role)
  end

  context "when the help desk user cannot be created" do
    before do
      create(:project_role, name: "Help desk")
      allow(OpenProject.logger).to receive(:error)
    end

    it "still enables the module and logs the failure" do
      project.enabled_modules.create!(name: "helpdesk")

      expect(project.reload.module_enabled?(:helpdesk)).to be(true)
      expect(OpenProject.logger).to have_received(:error).with(/Help desk user not added to project #{project.id}/)
    end
  end

  it "does not add the help desk user for other modules" do
    project.enabled_modules.create!(name: "calendar_view")

    expect(Member.where(project:)).to be_empty
  end
end
