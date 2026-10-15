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

require_relative "../../spec_helper"

RSpec.describe CostQuery, :reporting_query_helper do
  let(:project) { create(:project) }

  minimal_query

  describe "#chain" do
    around do |example|
      # FIXME: is there a better way to load all filter and groups?
      CostQuery::Filter.all && CostQuery::GroupBy.all
      previous_chain_initializer = described_class.chain_initializer.dup
      described_class.chain_initializer.clear
      example.run
    ensure
      described_class.chain_initializer.clear
      described_class.chain_initializer.push(*previous_chain_initializer)
    end

    it "contains NoFilter" do
      expect(query.chain).to be_a(CostQuery::Filter::NoFilter)
    end

    it "keeps NoFilter at bottom" do
      query.filter :project_id
      expect(query.chain.bottom).to be_a(CostQuery::Filter::NoFilter)
      expect(query.chain.top).not_to be_a(CostQuery::Filter::NoFilter)
    end

    it "remembers its correct parent" do
      query.group_by :project_id
      query.filter :project_id
      expect(query.chain.top.child.child.parent).to eq(query.chain.top.child)
    end

    it "places filter after a group_by" do
      query.group_by :project_id
      expect(query.chain.bottom.parent).to be_a(CostQuery::GroupBy::ProjectId)
      expect(query.chain.top).to be_a(CostQuery::GroupBy::ProjectId)

      query.filter :project_id
      expect(query.chain.bottom.parent).to be_a(CostQuery::Filter::ProjectId)
      expect(query.chain.top).to be_a(CostQuery::GroupBy::ProjectId)
    end

    it "places rows in front of columns when adding a column first" do
      query.column :project_id
      expect(query.chain.bottom.parent.type).to eq(:column)
      expect(query.chain.top.type).to eq(:column)

      query.row :project_id
      expect(query.chain.bottom.parent.type).to eq(:column)
      expect(query.chain.top.type).to eq(:row)
    end

    it "places rows in front of filters" do
      query.row :project_id
      expect(query.chain.bottom.parent.type).to eq(:row)
      expect(query.chain.top.type).to eq(:row)

      query.filter :project_id
      expect(query.chain.bottom.parent).to be_a(CostQuery::Filter::ProjectId)
      expect(query.chain.top).to be_a(CostQuery::GroupBy::ProjectId)
      expect(query.chain.top.type).to eq(:row)
    end

    it "returns all filters, including the NoFilter" do
      query.filter :project_id
      query.group_by :project_id
      expect(query.filters.size).to eq(2)
      expect(query.filters.map { |f| f.class.underscore_name }).to include "project_id"
    end

    it "returns all group_bys" do
      query.filter :project_id
      query.group_by :project_id
      expect(query.group_bys.size).to eq(1)
      expect(query.group_bys.map { |g| g.class.underscore_name }).to include "project_id"
    end

    it "initializes the chain through a block" do
      class TestFilter < Report::Filter::Base
        def self.engine
          CostQuery
        end
      end
      TestFilter.send(:initialize_query_with) { |query| query.filter(:project_id, value: project.id) }
      query.build_new_chain
      expect(query.filters.map { |f| f.class.underscore_name }).to include "project_id"
      expect(query.filters.detect { |f| f.class.underscore_name == "project_id" }.values).to eq(Array(project.id))
    end
  end
end
