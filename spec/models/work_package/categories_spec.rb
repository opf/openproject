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

RSpec.describe WorkPackage::Categories do
  let(:work_package) { create(:work_package) }
  let(:project) { work_package.project }

  describe "#categories" do
    let!(:zeta) { create(:category, project:, name: "zeta") }
    let!(:alpha) { create(:category, project:, name: "Alpha") }
    let!(:beta) { create(:category, project:, name: "beta") }

    before do
      [beta, zeta, alpha].each { |category| create(:work_package_category, work_package:, category:) }
    end

    it "returns the categories ordered by id" do
      expect(work_package.reload.categories).to eq [zeta, alpha, beta]
    end
  end

  it "deletes the category associations together with the work package" do
    create(:work_package_category, work_package:)

    expect { work_package.destroy }.to change(WorkPackageCategory, :count).by(-1)
  end
end
