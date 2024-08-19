# -- copyright
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
# ++

require "spec_helper"
require_relative "shared_contract_examples"

RSpec.describe Relations::UpdateContract do
  it_behaves_like "relation contract" do
    let(:relation) do
      build_stubbed(:relation,
                    from: relation_from,
                    to: relation_to,
                    relation_type:,
                    lag: relation_lag)
    end
  end

  describe "valid?" do
    create_shared_association_defaults_for_work_package_factory
    let(:current_user) { build_stubbed(:admin) }
    let(:contract) { described_class.new(relation, current_user) }

    context "when an isolated relation is reversed" do
      let(:relation) do
        create(:relation, relation_type: Relation::TYPE_BLOCKS)
      end

      before do
        relation.relation_type = Relation::TYPE_BLOCKED
      end

      it "is valid" do
        expect(contract).to be_valid
      end
    end

    context "when a relation that cannot be reversed is reversed" do
      let(:relation_from_wp) { create(:work_package) }
      let(:relation_to_wp) { create(:work_package) }
      let(:intermediary_wp) { create(:work_package) }

      let!(:to_intermediary_wp) do
        create(:relation,
               from: relation_from_wp,
               to: intermediary_wp,
               relation_type: Relation::TYPE_FOLLOWS)
      end
      let!(:from_intermediary_wp) do
        create(:relation,
               from: intermediary_wp,
               to: relation_to_wp,
               relation_type: Relation::TYPE_FOLLOWS)
      end

      let(:relation) do
        create(:relation,
               from: relation_from_wp,
               to: relation_to_wp,
               relation_type: Relation::TYPE_FOLLOWS)
      end

      before do
        relation.relation_type = Relation::TYPE_PRECEDES
      end

      it "is invalid" do
        expect(contract).not_to be_valid
      end
    end
  end
end
