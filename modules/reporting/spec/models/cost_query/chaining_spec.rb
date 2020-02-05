#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe CostQuery, type: :model, reporting_query_helper: true do
  let(:project) { FactoryBot.create(:project) }

  minimal_query

  describe '#chain' do
    before do
      #FIXME: is there a better way to load all filter and groups?
      CostQuery::Filter.all && CostQuery::GroupBy.all
      CostQuery.chain_initializer.clear
    end

    after(:all) do
      CostQuery.chain_initializer.clear
    end

    it "should contain NoFilter" do
      expect(@query.chain).to be_a(CostQuery::Filter::NoFilter)
    end

    it "should keep NoFilter at bottom" do
      @query.filter :project_id
      expect(@query.chain.bottom).to be_a(CostQuery::Filter::NoFilter)
      expect(@query.chain.top).not_to be_a(CostQuery::Filter::NoFilter)
    end

    it "should remember it's correct parent" do
      @query.group_by :project_id
      @query.filter :project_id
      expect(@query.chain.top.child.child.parent).to eq(@query.chain.top.child)
    end

    it "should place filter after a group_by" do
      @query.group_by :project_id
      expect(@query.chain.bottom.parent).to be_a(CostQuery::GroupBy::ProjectId)
      expect(@query.chain.top).to be_a(CostQuery::GroupBy::ProjectId)

      @query.filter :project_id
      expect(@query.chain.bottom.parent).to be_a(CostQuery::Filter::ProjectId)
      expect(@query.chain.top).to be_a(CostQuery::GroupBy::ProjectId)
    end

    it "should place rows in front of columns when adding a column first" do
      @query.column :project_id
      expect(@query.chain.bottom.parent.type).to eq(:column)
      expect(@query.chain.top.type).to eq(:column)

      @query.row :project_id
      expect(@query.chain.bottom.parent.type).to eq(:column)
      expect(@query.chain.top.type).to eq(:row)
    end

    it "should place rows in front of columns when adding a row first" do
      skip "This fails unreproducible on travis" if ENV['CI']
      @query.row :project_id
      expect(@query.chain.bottom.parent.type).to eq(:row)
      expect(@query.chain.top.type).to eq(:row)

      @query.column :project_id
      expect(@query.chain.bottom.parent.type).to eq(:column)
      expect(@query.chain.top.type).to eq(:row)
    end

    it "should place rows in front of filters" do
      @query.row :project_id
      expect(@query.chain.bottom.parent.type).to eq(:row)
      expect(@query.chain.top.type).to eq(:row)

      @query.filter :project_id
      expect(@query.chain.bottom.parent).to be_a(CostQuery::Filter::ProjectId)
      expect(@query.chain.top).to be_a(CostQuery::GroupBy::ProjectId)
      expect(@query.chain.top.type).to eq(:row)
    end

    it "should place columns in front of filters" do
      skip "This fails unreproducible on travis" if ENV['CI']
      @query.column :project_id
      expect(@query.chain.bottom.parent.type).to eq(:column)
      expect(@query.chain.top.type).to eq(:column)

      @query.filter :project_id
      expect(@query.chain.bottom.parent).to be_a(CostQuery::Filter::ProjectId)
      expect(@query.chain.top).to be_a(CostQuery::GroupBy::Base)
      expect(@query.chain.top.type).to eq(:column)
    end

    it "should return all filters, including the NoFilter" do
      @query.filter :project_id
      @query.group_by :project_id
      expect(@query.filters.size).to eq(2)
      expect(@query.filters.map {|f| f.class.underscore_name}).to include "project_id"
    end

    it "should return all group_bys" do
      @query.filter :project_id
      @query.group_by :project_id
      expect(@query.group_bys.size).to eq(1)
      expect(@query.group_bys.map {|g| g.class.underscore_name}).to include "project_id"
    end

    it "should initialize the chain through a block" do
      class TestFilter < Report::Filter::Base
        def self.engine
          CostQuery
        end
      end
      TestFilter.send(:initialize_query_with) {|query| query.filter(:project_id, value: project.id)}
      @query.build_new_chain
      expect(@query.filters.map {|f| f.class.underscore_name}).to include "project_id"
      expect(@query.filters.detect {|f| f.class.underscore_name == "project_id"}.values).to eq(Array(project.id))
    end

    context "store and load" do
      before do
        @query.filter :project_id, value: project.id
        @query.filter :cost_type_id, value: CostQuery::Filter::CostTypeId.available_values.first
        @query.filter :category_id, value: CostQuery::Filter::CategoryId.available_values.first
        @query.group_by :activity_id
        @query.group_by :cost_object_id
        @query.group_by :cost_type_id
        @new_query = CostQuery.deserialize(@query.serialize)
      end

      it "should serialize the chain correctly" do
        [:filters, :group_bys].each do |type|
          @query.send(type).each do |chainable|
            expect(@query.serialize[type].collect{|c| c[0]}).to include chainable.class.name.demodulize
          end
        end
      end

      it "should deserialize a serialized query correctly" do
        expect(@new_query.serialize).to eq(@query.serialize)
      end

      it "should keep the order of group bys" do
        @query.group_bys.each_with_index do |group_by, index|
          # check for order
          @new_query.group_bys.each_with_index do |g, ix|
            if g.class.name == group_by.class.name
              expect(ix).to eq(index)
            end
          end
        end
      end

      it "should keep the right filter values" do
        @query.filters.each_with_index do |filter, index|
          # check for presence
          expect(@new_query.filters.any? do |f|
            f.class.name == filter.class.name && (filter.respond_to?(:values) ? f.values == filter.values : true)
          end).to be_truthy
        end
      end
    end
  end

  describe Report::Chainable do
    describe '#top' do
      before { @chain = Report::Chainable.new }

      it "returns for an one element long chain that chain as top" do
        expect(@chain.top).to eq(@chain)
        expect(@chain).to be_top
      end

      it "does not keep the old top when prepending elements" do
        Report::Chainable.new @chain
        expect(@chain.top).not_to eq(@chain)
        expect(@chain).not_to be_top
      end

      it "sets new top when prepending elements" do
        current = @chain
        10.times do
          old, current = current, CostQuery::Chainable.new(current)
          expect(old.top).to eq(current)
          expect(@chain.top).to eq(current)
        end
      end
    end

    describe '#inherited_attribute' do
      before do
        @a = Class.new Report::Chainable
        @a.inherited_attribute :foo, default: 42
        @b = Class.new @a
        @c = Class.new @a
        @d = Class.new @b
      end

      it 'takes default argument' do
        expect(@a.foo).to eq(42)
        expect(@b.foo).to eq(42)
        expect(@c.foo).to eq(42)
        expect(@d.foo).to eq(42)
      end

      it 'inherits values' do
        @a.foo 1337
        expect(@d.foo).to eq(1337)
      end

      it 'does not change values of parents and akin' do
        @b.foo 1337
        expect(@a.foo).not_to eq(1337)
        expect(@c.foo).not_to eq(1337)
      end

      it 'is able to map values' do
        @a.inherited_attribute :bar, map: proc { |x| x*2 }
        @a.bar 21
        expect(@a.bar).to eq(42)
      end

      describe '#list' do
        it "merges lists" do
          @a.inherited_attribute :bar, list: true
          @a.bar 1; @b.bar 2; @d.bar 3, 4
          expect(@a.bar).to eq([1])
          expect(@b.bar.sort).to eq([1, 2])
          expect(@c.bar.sort).to eq([1])
          expect(@d.bar.sort).to eq([1, 2, 3, 4])
        end

        it "is able to map lists" do
          @a.inherited_attribute :bar, list: true, map: :to_s
          @a.bar 1; @b.bar 1; @d.bar 1
          expect(@a.bar).to eq(%w[1])
          expect(@b.bar).to eq(%w[1 1])
          expect(@c.bar).to eq(%w[1])
          expect(@d.bar).to eq(%w[1 1 1])
        end

        it "is able to produce uniq lists" do
          @a.inherited_attribute :bar, list: true, uniq: true
          @a.bar 1, 1, 2
          @b.bar 2, 3
          expect(@b.bar.sort).to eq([1, 2, 3])
        end

        it "keeps old entries" do
          @a.inherited_attribute :bar, list: true
          @a.bar 1
          @a.bar 2
          expect(@a.bar.sort).to eq([1, 2])
        end
      end
    end

    describe '#display' do
      it "should give display? == false when a filter says dont_display!" do
        class TestFilter < Report::Filter::Base
          dont_display!
        end
        expect(TestFilter.display?).to be false
        Object.send(:remove_const, :TestFilter)
      end

      it "should give display? == true when a filter doesn't specify it's visibility" do
        class TestFilter < Report::Filter::Base
        end
        expect(TestFilter.display?).to be true
        Object.send(:remove_const, :TestFilter)
      end

      it "should give display? == true when a filter says display!" do
        class TestFilter < Report::Filter::Base
          display!
        end
        expect(TestFilter.display?).to be true
        Object.send(:remove_const, :TestFilter)
      end
    end

    describe '#selectable' do
      it "should give selectable? == false when a filter says not_selectable!" do
        class TestFilter < Report::Filter::Base
          not_selectable!
        end
        expect(TestFilter.selectable?).to be false
        Object.send(:remove_const, :TestFilter)
      end

      it "should give selectable? == true when a filter doesn't specify it's selectability" do
        class TestFilter < Report::Filter::Base
        end
        expect(TestFilter.selectable?).to be true
        Object.send(:remove_const, :TestFilter)
      end

      it "should give selectable? == true when a filter says selectable!" do
        class TestFilter < Report::Filter::Base
          selectable!
        end
        expect(TestFilter.selectable?).to be true
        Object.send(:remove_const, :TestFilter)
      end
    end
  end
end
