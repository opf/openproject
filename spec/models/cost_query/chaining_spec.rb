require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe CostQuery do
  minimal_query

  fixtures :users
  fixtures :cost_types
  fixtures :cost_entries
  fixtures :rates
  fixtures :projects
  fixtures :issues
  fixtures :trackers
  fixtures :time_entries
  fixtures :enumerations
  fixtures :issue_statuses
  fixtures :roles
  fixtures :issue_categories
  fixtures :versions

  describe :chain do
    it "should contain NoFilter" do
      @query.chain.should be_a(CostQuery::Filter::NoFilter)
    end

    it "should keep NoFilter at bottom" do
      @query.filter :project_id
      @query.chain.bottom.should be_a(CostQuery::Filter::NoFilter)
      @query.chain.top.should_not be_a(CostQuery::Filter::NoFilter)
    end

    it "should not remember it's correct parent" do
      @query.group_by :project_id
      @query.filter :project_id
      @query.chain.top.child.child.parent.should == @query.chain.top.child
    end

    it "should place filter after a group_by" do
      @query.group_by :project_id
      @query.chain.bottom.parent.should be_a(CostQuery::GroupBy::ProjectId)
      @query.chain.top.should be_a(CostQuery::GroupBy::ProjectId)

      @query.filter :project_id
      @query.chain.bottom.parent.should be_a(CostQuery::Filter::ProjectId)
      @query.chain.top.should be_a(CostQuery::GroupBy::ProjectId)
    end

    it "should place rows in front of columns when adding a column first" do
      @query.column :project_id
      @query.chain.bottom.parent.type.should == :column
      @query.chain.top.type.should == :column

      @query.row :project_id
      @query.chain.bottom.parent.type.should == :column
      @query.chain.top.type.should == :row
    end

    it "should place rows in front of columns when adding a row first" do
      @query.row :project_id
      @query.chain.bottom.parent.type.should == :row
      @query.chain.top.type.should == :row

      @query.column :project_id
      @query.chain.bottom.parent.type.should == :column
      @query.chain.top.type.should == :row
    end

    it "should place rows in front of filters" do
      @query.row :project_id
      @query.chain.bottom.parent.type.should == :row
      @query.chain.top.type.should == :row

      @query.filter :project_id
      @query.chain.bottom.parent.should be_a(CostQuery::Filter::ProjectId)
      @query.chain.top.should be_a(CostQuery::GroupBy::ProjectId)
      @query.chain.top.type.should == :row
    end

    it "should place columns in front of filters" do
      @query.column :project_id
      @query.chain.bottom.parent.type.should == :column
      @query.chain.top.type.should == :column

      @query.filter :project_id
      @query.chain.bottom.parent.should be_a(CostQuery::Filter::ProjectId)
      @query.chain.top.should be_a(CostQuery::GroupBy::Base)
      @query.chain.top.type.should == :column
    end

    it "should return all filters, including the NoFilter" do
      @query.filter :project_id
      @query.group_by :project_id
      @query.filters.size.should == 2
      @query.filters.collect {|f| f.class.underscore_name}.should include "project_id"
    end

    it "should return all group_bys" do
      @query.filter :project_id
      @query.group_by :project_id
      @query.group_bys.size.should == 1
      @query.group_bys.collect {|g| g.class.underscore_name}.should include "project_id"
    end

    it "should initialize the chain with a given block" do
      class TestFilter < CostQuery::Filter::Base
        initialize_query_with {|query| query.filter(:project_id, :value => Project.all.first.id)}
      end
      @query.build_new_chain
      @query.filters.size.should == 3
      @query.filters.collect {|f| f.class.underscore_name}.should include "project_id"
    end

    it "should serialize the chain correctly" do
      @query.filter :project_id, :value => Project.all.first.id
      @query.filter :cost_type_id, :value => CostQuery::Filter::CostTypeId.available_values.first
      @query.filter :category_id, :value => CostQuery::Filter::CategoryId.available_values.first
      @query.group_by :activity_id
      @query.group_by :cost_object_id
      @query.group_by :cost_type_id
      [:filters, :group_bys].each do |type|
        @query.send(type).each do |chainable|
          @query.serialize[type].collect{|c| c[0]}.should include chainable.class.name.demodulize
        end
      end
    end
  end

  describe CostQuery::Chainable do
    describe :top do
      before { @chain = CostQuery::Chainable.new }

      it "returns for an one element long chain that chain as top" do
        @chain.top.should == @chain
        @chain.should be_top
      end

      it "does not keep the old top when prepending elements" do
        CostQuery::Chainable.new @chain
        @chain.top.should_not == @chain
        @chain.should_not be_top
      end

      it "sets new top when prepending elements" do
        current = @chain
        10.times do
          old, current = current, CostQuery::Chainable.new(current)
          old.top.should == current
          @chain.top.should == current
        end
      end
    end

    describe :inherited_attribute do
      before do
        @a = Class.new CostQuery::Chainable
        @a.inherited_attribute :foo, :default => 42
        @b = Class.new @a
        @c = Class.new @a
        @d = Class.new @b
      end

      it 'takes default argument' do
        @a.foo.should == 42
        @b.foo.should == 42
        @c.foo.should == 42
        @d.foo.should == 42
      end

      it 'inherits values' do
        @a.foo 1337
        @d.foo.should == 1337
      end

      it 'does not change values of parents and akin' do
        @b.foo 1337
        @a.foo.should_not == 1337
        @c.foo.should_not == 1337
      end

      it 'is able to map values' do
        @a.inherited_attribute :bar, :map => proc { |x| x*2 }
        @a.bar 21
        @a.bar.should == 42
      end

      describe :list do
        it "merges lists" do
          @a.inherited_attribute :bar, :list => true
          @a.bar 1; @b.bar 2; @d.bar 3, 4
          @a.bar.should == [1]
          @b.bar.sort.should == [1, 2]
          @c.bar.sort.should == [1]
          @d.bar.sort.should == [1, 2, 3, 4]
        end

        it "is able to map lists" do
          @a.inherited_attribute :bar, :list => true, :map => :to_s
          @a.bar 1; @b.bar 1; @d.bar 1
          @a.bar.should == %w[1]
          @b.bar.should == %w[1 1]
          @c.bar.should == %w[1]
          @d.bar.should == %w[1 1 1]
        end

        it "is able to produce uniq lists" do
          @a.inherited_attribute :bar, :list => true, :uniq => true
          @a.bar 1, 1, 2
          @b.bar 2, 3
          @b.bar.sort.should == [1, 2, 3]
        end

        it "keeps old entries" do
          @a.inherited_attribute :bar, :list => true
          @a.bar 1
          @a.bar 2
          @a.bar.sort.should == [1, 2]
        end
      end
    end

    describe :display do
      it "should give display? == false when a filter says dont_display!" do
        class TestFilter < CostQuery::Filter::Base
          dont_display!
        end
        TestFilter.display?.should be false
        Object.send(:remove_const, :TestFilter)
      end

      it "should give display? == true when a filter doesn't specify it's visibility" do
        class TestFilter < CostQuery::Filter::Base
        end
        TestFilter.display?.should be true
        Object.send(:remove_const, :TestFilter)
      end

      it "should give display? == true when a filter says display!" do
        class TestFilter < CostQuery::Filter::Base
          display!
        end
        TestFilter.display?.should be true
        Object.send(:remove_const, :TestFilter)
      end
    end

    describe :selectable do
      it "should give selectable? == false when a filter says not_selectable!" do
        class TestFilter < CostQuery::Filter::Base
          not_selectable!
        end
        TestFilter.selectable?.should be false
        Object.send(:remove_const, :TestFilter)
      end

      it "should give selectable? == true when a filter doesn't specify it's selectability" do
        class TestFilter < CostQuery::Filter::Base
        end
        TestFilter.selectable?.should be true
        Object.send(:remove_const, :TestFilter)
      end

      it "should give selectable? == true when a filter says selectable!" do
        class TestFilter < CostQuery::Filter::Base
          selectable!
        end
        TestFilter.selectable?.should be true
        Object.send(:remove_const, :TestFilter)
      end
    end
  end
end
