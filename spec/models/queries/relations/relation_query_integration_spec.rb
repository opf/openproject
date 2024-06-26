# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++

require "spec_helper"

RSpec.describe Queries::Relations::RelationQuery do
  let(:instance) { described_class.new }

  shared_let(:project) { create(:project) }
  shared_let(:from_work_package) { create(:work_package, project:) }
  shared_let(:relates_work_package) { create(:work_package, project:) }
  shared_let(:follows_work_package) { create(:work_package, project:) }
  shared_let(:blocks_work_package) { create(:work_package, project:) }
  shared_let(:invisible_work_package) { create(:work_package) }
  shared_let(:relates_relation) { create(:relation, from: from_work_package, to: relates_work_package, relation_type: "relates") }
  shared_let(:follows_relation) { create(:relation, from: from_work_package, to: follows_work_package, relation_type: "follows") }
  shared_let(:blocks_relation) { create(:relation, from: from_work_package, to: blocks_work_package, relation_type: "blocks") }
  shared_let(:invisible_relation) { create(:relation, from: invisible_work_package, to: relates_work_package) }

  shared_current_user { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

  describe "#results" do
    subject { instance.results }

    context "without a filter" do
      it "is the same as getting all the relations - ordered by id desc" do
        expect(subject).to eq [blocks_relation, follows_relation, relates_relation]
      end
    end

    context "with a type filter" do
      before do
        instance.where("type", "=", %w[follows blocks])
      end

      it "returns the relations of the type matching the filter" do
        expect(subject).to eq [blocks_relation, follows_relation]
      end
    end

    context "with a from filter" do
      before do
        instance.where("from_id", "=", [from_work_package.id.to_s])
      end

      it "returns all relations originating from the work package with the id specified" do
        expect(subject).to eq [blocks_relation, follows_relation, relates_relation]
      end
    end

    context "with a to filter" do
      before do
        instance.where("to_id", "=", [blocks_work_package.id.to_s])
      end

      it "returns all relations ending at the work package with the id specified" do
        expect(subject).to eq [blocks_relation]
      end
    end

    context "with an order by id asc" do
      before do
        instance.order(id: :asc)
      end

      it "returns the relations ordered by id asc" do
        expect(subject).to eq [relates_relation, follows_relation, blocks_relation]
      end
    end
  end
end
