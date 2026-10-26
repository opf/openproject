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

require "spec_helper"

RSpec.describe SquashTMIntegration::WorkPackageLink do
  it "belongs to a work package" do
    link = create(:squashtm_work_package_link)

    expect(link.work_package).to be_a(WorkPackage)
    expect(link.project).to eq(link.work_package.project)
  end

  it "allows only one link per work package" do
    existing = create(:squashtm_work_package_link)

    duplicate = build(:squashtm_work_package_link, work_package: existing.work_package)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors).to be_added(:work_package_id, :taken, value: existing.work_package_id)
  end

  it "is removed together with its work package" do
    link = create(:squashtm_work_package_link)

    expect { link.work_package.destroy }.to change(described_class, :count).by(-1)
  end
end
