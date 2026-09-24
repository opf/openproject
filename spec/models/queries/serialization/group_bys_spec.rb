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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Queries::Serialization::GroupBys do
  # NotificationQuery is a query class that registers group bys.
  let(:query_class) { Queries::Notifications::NotificationQuery }
  let(:instance) { described_class.new(query_class) }

  describe "#load" do
    it "instantiates the registered group by for each attribute" do
      expect(instance.load(%w[reason project]).map(&:class))
        .to eq([Queries::Notifications::GroupBys::GroupByReason,
                Queries::Notifications::GroupBys::GroupByProject])
    end

    it "keeps the order of the serialized attributes" do
      expect(instance.load(%w[project reason]).map(&:attribute)).to eq(%i[project reason])
    end

    it "returns an empty array for nil" do
      expect(instance.load(nil)).to eq([])
    end

    it "returns an empty array for an empty array" do
      expect(instance.load([])).to eq([])
    end

    it "degrades an unknown attribute instead of raising" do
      group_bys = instance.load(%w[does_not_exist])

      expect(group_bys.map(&:class)).to eq([Queries::GroupBys::NotExistingGroupBy])
      expect(group_bys.first).not_to be_valid
    end

    it "resolves against the registry of the class it was built for" do
      # UserQuery registers no group bys at all, so nothing is resolvable there.
      expect(described_class.new(UserQuery).load(%w[reason]).map(&:class))
        .to eq([Queries::GroupBys::NotExistingGroupBy])
    end
  end

  describe "#dump" do
    # The attribute is dumped rather than #name, which may be the underlying SQL
    # column - GroupByProject is keyed :project but names the project_id column -
    # so that the dumped value can be loaded again.
    it "reduces the group bys to their attributes" do
      expect(instance.dump(instance.load(%w[reason project]))).to eq(%w[reason project])
    end

    it "returns an empty array for no group bys" do
      expect(instance.dump([])).to eq([])
    end
  end

  it "round trips" do
    expect(instance.dump(instance.load(%w[reason project]))).to eq(%w[reason project])
  end
end
