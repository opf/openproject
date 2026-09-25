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

RSpec.describe WorkPackages::Scopes::BacklogEligible do
  let(:user) { create(:admin) }
  let(:included_type) { create(:type, name: "Story") }
  let(:excluded_type) { create(:type, name: "Task") }
  let(:open_status) { create(:status, is_closed: false) }
  let(:done_status) { create(:status, is_closed: true) }
  let(:project) do
    create(:project,
           enabled_module_names: %w[backlogs],
           types: [included_type, excluded_type]) do |p|
      p.backlog_excluded_types = [excluded_type]
      p.done_status_ids = [done_status.id]
    end
  end

  current_user { user }

  subject(:eligible) { WorkPackage.backlog_eligible }

  describe ".backlog_eligible" do
    it "returns only work packages excluded by neither their type nor their status" do
      eligible_work_package = create(:work_package, project:, type: included_type, status: open_status)
      create(:work_package, project:, type: excluded_type, status: open_status)
      create(:work_package, project:, type: included_type, status: done_status)
      create(:work_package, project:, type: excluded_type, status: done_status)

      expect(eligible).to contain_exactly(eligible_work_package)
    end

    it "keeps the conditions of the scope it is chained onto" do
      create(:work_package, project:, type: included_type, status: open_status)
      other_project_work_package = create(:work_package, type: included_type, status: open_status)

      expect(WorkPackage.where(project: other_project_work_package.project).backlog_eligible)
        .to contain_exactly(other_project_work_package)
    end
  end
end
