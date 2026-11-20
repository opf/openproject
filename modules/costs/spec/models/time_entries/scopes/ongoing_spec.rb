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

RSpec.describe TimeEntries::Scopes::Ongoing do
  let(:user) { create(:user) }
  let(:project) { create(:project, public: false) }
  let(:work_package) { create(:work_package, project: project) }
  let(:ongoing_time_entry) { create(:time_entry, user:, entity: work_package, ongoing: true) }
  let(:work_package_role) { create(:work_package_role, permissions: work_package_permissions) }

  subject { TimeEntry.visible_ongoing(user) }

  context "when the user has log_own_time permission directly on the work package" do
    let(:work_package_permissions) { [:log_own_time] }

    before do
      create(:member, project: project, entity: work_package, user:, roles: [work_package_role])
    end

    it "returns the visible, ongoing time entry" do
      expect(subject).to contain_exactly(ongoing_time_entry)
    end
  end
end
