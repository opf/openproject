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

RSpec.describe WorkPackage, "duplicates/duplicated_by relations" do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:work_package) { create(:work_package, subject: "original") }
  shared_let(:duplicate) { create(:work_package, subject: "duplicate") }
  shared_let(:relation) do
    create(:relation,
           from: duplicate,
           to: work_package,
           relation_type: Relation::TYPE_DUPLICATES)
  end

  context "when work package is closed" do
    let(:closed_status) { create(:closed_status) }

    it "updates the duplicate" do
      expect(duplicate.status).not_to eq(closed_status)

      work_package.status = closed_status
      work_package.save!
      duplicate.reload

      expect(duplicate.status).to eq(closed_status)
      journal = duplicate.journals.last

      expect(journal.user).to eq(User.system)
      expect(journal.cause).to eq("type" => "work_package_duplicate_closed", "work_package_id" => work_package.id)
    end
  end
end
