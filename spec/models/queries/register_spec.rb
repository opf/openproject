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
  let(:unregistered_query) { Class.new }

  describe "for a query that never registered anything" do
    it "has no filters" do
      expect(described_class.filters[unregistered_query]).to eq([])
    end

    it "has no excluded filters" do
      expect(described_class.excluded_filters[unregistered_query]).to eq([])
    end

    it "has no orders" do
      expect(described_class.orders[unregistered_query]).to eq([])
    end

    it "has no selects" do
      expect(described_class.selects[unregistered_query]).to eq([])
    end

    it "has no group bys" do
      expect(described_class.group_bys[unregistered_query]).to eq([])
    end
  end

  describe ".register" do
    let(:query) { Class.new }
    let(:filter_class) { Class.new }
    let(:excluded_filter_class) { Class.new }
    let(:order_class) { Class.new }
    let(:select_class) { Class.new }
    let(:group_by_class) { Class.new }

    let!(:registration) do
      # `register` instance_execs the block on a `Registration`, so the let helpers
      # have to be captured as locals to be reachable from inside it.
      filter = filter_class
      excluded_filter = excluded_filter_class
      order = order_class
      select = select_class
      group_by = group_by_class

      described_class.register(query) do
        filter filter
        filter excluded_filter
        exclude excluded_filter
        order order
        select select
        group_by group_by
      end
    end

    it "registers the filters" do
      expect(described_class.filters[query]).to contain_exactly(filter_class, excluded_filter_class)
    end

    it "registers the excluded filter" do
      expect(described_class.excluded_filters[query]).to contain_exactly(excluded_filter_class)
    end

    it "registers the order" do
      expect(described_class.orders[query]).to contain_exactly(order_class)
    end

    it "registers the select" do
      expect(described_class.selects[query]).to contain_exactly(select_class)
    end

    it "registers the group by" do
      expect(described_class.group_bys[query]).to contain_exactly(group_by_class)
    end

    it "leaves the filters of another query untouched" do
      expect(described_class.filters[unregistered_query]).to eq([])
    end

    it "leaves the excluded filters of another query untouched" do
      expect(described_class.excluded_filters[unregistered_query]).to eq([])
    end
  end
end
