require 'will_paginate/array'
require 'spec_helper'

describe WillPaginate::Collection do

  before :all do
    @simple = ('a'..'e').to_a
  end

  it "should be a subset of original collection" do
    @simple.paginate(:page => 1, :per_page => 3).should == %w( a b c )
  end

  it "can be shorter than per_page if on last page" do
    @simple.paginate(:page => 2, :per_page => 3).should == %w( d e )
  end

  it "should include whole collection if per_page permits" do
    @simple.paginate(:page => 1, :per_page => 5).should == @simple
  end

  it "should be empty if out of bounds" do
    @simple.paginate(:page => 2, :per_page => 5).should be_empty
  end
  
  it "should default to 1 as current page and 30 per-page" do
    result = (1..50).to_a.paginate
    result.current_page.should == 1
    result.size.should == 30
  end

  it "should give total_entries precedence over actual size" do
    %w(a b c).paginate(:total_entries => 5).total_entries.should == 5
  end

  it "should be an augmented Array" do
    entries = %w(a b c)
    collection = create(2, 3, 10) do |pager|
      pager.replace(entries).should == entries
    end

    collection.should == entries
    for method in %w(total_pages each offset size current_page per_page total_entries)
      collection.should respond_to(method)
    end
    collection.should be_kind_of(Array)
    collection.entries.should be_instance_of(Array)
    # TODO: move to another expectation:
    collection.offset.should == 3
    collection.total_pages.should == 4
    collection.should_not be_out_of_bounds
  end

  describe "previous/next pages" do
    it "should have previous_page nil when on first page" do
      collection = create(1, 1, 3)
      collection.previous_page.should be_nil
      collection.next_page.should == 2
    end
    
    it "should have both prev/next pages" do
      collection = create(2, 1, 3)
      collection.previous_page.should == 1
      collection.next_page.should == 3
    end
    
    it "should have next_page nil when on last page" do
      collection = create(3, 1, 3)
      collection.previous_page.should == 2
      collection.next_page.should be_nil
    end
  end

  describe "out of bounds" do
    it "is out of bounds when page number is too high" do
      create(2, 3, 2).should be_out_of_bounds
    end

    it "isn't out of bounds when inside collection" do
      create(1, 3, 2).should_not be_out_of_bounds
    end

    it "isn't out of bounds when the collection is empty" do
      collection = create(1, 3, 0)
      collection.should_not be_out_of_bounds
      collection.total_pages.should == 1
    end
  end

  describe "guessing total count" do
    it "can guess when collection is shorter than limit" do
      collection = create { |p| p.replace array }
      collection.total_entries.should == 8
    end
    
    it "should allow explicit total count to override guessed" do
      collection = create(2, 5, 10) { |p| p.replace array }
      collection.total_entries.should == 10
    end
    
    it "should not be able to guess when collection is same as limit" do
      collection = create { |p| p.replace array(5) }
      collection.total_entries.should be_nil
    end
    
    it "should not be able to guess when collection is empty" do
      collection = create { |p| p.replace array(0) }
      collection.total_entries.should be_nil
    end
    
    it "should be able to guess when collection is empty and this is the first page" do
      collection = create(1) { |p| p.replace array(0) }
      collection.total_entries.should == 0
    end
  end

  it "should not respond to page_count anymore" do
    Proc.new { create.page_count }.should raise_error(NoMethodError)
  end

  it "inherits per_page from global value" do
    collection = described_class.new(1)
    collection.per_page.should == 30
  end

  private
  
    def create(page = 2, limit = 5, total = nil, &block)
      if block_given?
        described_class.create(page, limit, total, &block)
      else
        described_class.new(page, limit, total)
      end
    end

    def array(size = 3)
      Array.new(size)
    end
end
