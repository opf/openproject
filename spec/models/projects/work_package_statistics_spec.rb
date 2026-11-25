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

RSpec.describe Projects::WorkPackageStatistics do
  shared_let(:open_status) { create(:status) }
  shared_let(:closed_status) { create(:closed_status) }
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }
  shared_let(:empty_project) { create(:project) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages view_project],
                                             empty_project => %i[view_work_packages view_project] })
  end

  let(:today) { Time.zone.today }

  before do
    create(:work_package, project:, status: open_status, due_date: today - 2.days)
    create(:work_package, project:, status: open_status, due_date: today + 2.days)
    create(:work_package, project:, status: open_status)
    create(:work_package, project:, status: closed_status, due_date: today - 2.days)
    create(:work_package, project: other_project, status: closed_status)
  end

  subject(:statistics) do
    Project.with_work_package_statistics(user).index_by(&:id)
  end

  it "counts total, open, closed and overdue work packages per project" do
    expect(statistics[project.id]).to have_attributes(
      work_packages_total: 4,
      work_packages_open: 3,
      work_packages_closed: 1,
      work_packages_overdue: 1,
      work_packages_completion: 25
    )
  end

  it "returns zero for projects without work packages" do
    expect(statistics[empty_project.id]).to have_attributes(
      work_packages_total: 0,
      work_packages_completion: 0
    )
  end

  it "does not count work packages the user cannot see" do
    expect(statistics[other_project.id]).to have_attributes(work_packages_total: 0)
  end
end
