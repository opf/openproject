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

RSpec.describe Category do
  let(:project) { create(:project) }
  let(:created_category) { create(:category, project:, assigned_to: assignee) }
  let(:assignee) { nil }

  describe "#create" do
    it "is creatable and takes the attributes" do
      category = described_class.create project:, name: "New category"

      expect(category.attributes.slice("project_id", "name"))
        .to eq("project_id" => project.id, "name" => "New category")
    end

    context "with a group assignment" do
      let(:group) do
        create(:group,
               member_with_permissions: { project => [] })
      end
      let(:assignee) { group }

      it "allows to assign groups" do
        expect(created_category.assigned_to)
          .to eq group
      end
    end
  end

  describe "#destroy" do
    let!(:work_package) { create(:work_package, project:, category: created_category) }

    it "nullifies existing assignments to a work package" do
      created_category.destroy

      expect(work_package.reload.category_id)
        .to be_nil
    end

    it "allows reassigning to a different category" do
      other_category = create(:category, project:)

      created_category.destroy(other_category)

      expect(work_package.reload.category)
        .to eq other_category
    end
  end
end
