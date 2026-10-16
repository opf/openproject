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

RSpec.describe Versions::SpentTime do
  let(:project) { create(:project) }
  let(:version) { create(:version, project:) }
  let(:other_version) { create(:version, project:) }

  describe "#spent_hours" do
    context "when a work package targets two versions" do
      let!(:work_package) { create(:work_package, project:, version:) }

      before do
        work_package.work_package_versions.create!(version: other_version, kind: "target")
        create(:time_entry, entity: work_package, project:, hours: 2)
      end

      it "sums spent time for both versions" do
        expect(version.spent_hours).to eq 2.0
        expect(other_version.spent_hours).to eq 2.0
      end
    end

    context "when a work package only carries the legacy version_id without a target row" do
      let!(:work_package) { create(:work_package, project:, version:) }

      before do
        create(:time_entry, entity: work_package, project:, hours: 2)
        WorkPackageVersion.delete_all
      end

      it "is not counted" do
        expect(version.spent_hours).to eq 0.0
      end
    end
  end
end
