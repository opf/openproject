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

RSpec.describe WorkPackage, "blocks/blocked_by relations" do
  create_shared_association_defaults_for_work_package_factory
  shared_let(:work_package) { create(:work_package, subject: "blocked wp") }

  it "is not blocked by default" do
    expect(work_package).not_to be_blocked
    expect(work_package.blockers).to be_empty
  end

  context "with blocking work package" do
    shared_let(:blocker) { create(:work_package, subject: "blocking wp") }
    shared_let(:relation) do
      create(:relation,
             from: blocker,
             to: work_package,
             relation_type: Relation::TYPE_BLOCKS)
    end

    it "is being blocked" do
      expect(work_package).to be_blocked
      expect(work_package.blockers).to include blocker
    end

    context "when work package is closed" do
      let(:closed_status) { create(:closed_status) }

      before do
        work_package.update_column :status_id, closed_status.id
      end

      it "is not blocked" do
        expect(work_package).not_to be_blocked
        expect(work_package.blockers).to be_empty
      end
    end
  end
end
