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

RSpec.describe WorkPackage::Ancestors do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:project2) { create(:project) }

  let!(:root_work_package) do
    create(:work_package,
           project:)
  end

  let!(:intermediate) do
    create(:work_package,
           parent: root_work_package,
           project:)
  end
  let!(:intermediate_project2) do
    create(:work_package,
           parent: root_work_package,
           project: project2)
  end
  let!(:leaf) do
    create(:work_package,
           parent: intermediate,
           project:)
  end
  let!(:leaf_project2) do
    create(:work_package,
           parent: intermediate_project2,
           project:)
  end

  let(:view_role) do
    build(:project_role,
          permissions: [:view_work_packages])
  end

  let(:none_role) do
    build(:project_role,
          permissions: [])
  end

  let(:leaf_ids) { [leaf.id, leaf_project2.id] }
  let(:intermediate_ids) { [intermediate.id, intermediate_project2.id] }

  subject { WorkPackage.aggregate_ancestors(ids, user) }

  before do
    allow(Setting).to receive(:cross_project_work_package_relations?).and_return(true)
    login_as(user)
  end

  context "with permission in the first project" do
    before do
      create(:member,
             user:,
             project:,
             roles: [view_role])
    end

    describe "fetching from db" do
      it "returns the same results" do
        expect(leaf.visible_ancestors(user)).to eq([root_work_package, intermediate])
      end
    end

    describe "leaf ids" do
      let(:ids) { leaf_ids }

      it "returns ancestors for the leaf in project 1" do
        expect(subject).to be_a(Hash)
        expect(subject.keys.length).to eq(2)

        expect(subject[leaf.id]).to eq([root_work_package, intermediate])
        expect(subject[leaf_project2.id]).to eq([root_work_package])
      end
    end

    describe "intermediate ids" do
      let(:ids) { intermediate_ids }

      it "returns all ancestors in project 1" do
        expect(subject).to be_a(Hash)
        expect(subject.keys.length).to eq(2)

        expect(subject[intermediate.id]).to eq([root_work_package])
        expect(subject[intermediate_project2.id]).to eq([root_work_package])
      end
    end

    context "and permission in second project" do
      before do
        create(:member,
               user:,
               project: project2,
               roles: [view_role])
      end

      describe "leaf ids" do
        let(:ids) { leaf_ids }

        it "returns all ancestors" do
          expect(subject).to be_a(Hash)
          expect(subject.keys.length).to eq(2)

          expect(subject[leaf.id]).to eq([root_work_package, intermediate])
          expect(subject[leaf_project2.id]).to eq([root_work_package, intermediate_project2])
        end
      end
    end
  end

  context "no permissions" do
    before do
      create(:member,
             user:,
             project:,
             roles: [none_role])
    end

    describe "leaf ids" do
      let(:ids) { leaf_ids }

      it "returns no results for all ids" do
        expect(subject).to be_a(Hash)
        expect(subject.keys.length).to eq(0)
      end
    end
  end
end
