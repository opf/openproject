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

RSpec.describe Queries::Register do
  describe "the registries" do
    # A query class registering none of a given kind is normal - most notably
    # group bys, which only a handful of queries declare - so the registries must
    # never hand out nil.
    %i[filters orders selects group_bys].each do |kind|
      it "#{kind} is a hash, even before anything is registered" do
        expect(described_class.public_send(kind)).to be_a(Hash)
      end

      it "#{kind} returns an empty array for a query class that registered none" do
        expect(described_class.public_send(kind)[Class.new]).to eq([])
      end
    end

    it "excluded_filters is an array" do
      expect(described_class.excluded_filters).to be_an(Array)
    end
  end

  describe "registering" do
    let(:query_class) { Class.new }
    let(:filter_class) { Class.new }
    let(:order_class) { Class.new }
    let(:select_class) { Class.new }
    let(:group_by_class) { Class.new }

    it "collects the registered classes per query class" do
      # Captured in locals because inside the block self is the Registration,
      # where `filter` and friends are the DSL methods.
      a_filter = filter_class
      an_order = order_class
      a_select = select_class
      a_group_by = group_by_class

      described_class.register(query_class) do
        filter a_filter
        order an_order
        select a_select
        group_by a_group_by
      end

      expect(described_class.filters[query_class]).to eq([filter_class])
      expect(described_class.orders[query_class]).to eq([order_class])
      expect(described_class.selects[query_class]).to eq([select_class])
      expect(described_class.group_bys[query_class]).to eq([group_by_class])
    end
  end
end
