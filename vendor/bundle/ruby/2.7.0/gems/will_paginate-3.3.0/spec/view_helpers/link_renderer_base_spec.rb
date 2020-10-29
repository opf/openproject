require 'spec_helper'
require 'will_paginate/view_helpers/link_renderer_base'
require 'will_paginate/collection'

describe WillPaginate::ViewHelpers::LinkRendererBase do
  
  before do
    @renderer = described_class.new
  end
  
  it "should raise error when unprepared" do
    lambda {
      @renderer.pagination
    }.should raise_error
  end
  
  it "should prepare with collection and options" do
    prepare({})
    @renderer.send(:current_page).should == 1
  end
  
  it "should have total_pages accessor" do
    prepare :total_pages => 42
    @renderer.send(:total_pages).should == 42
  end
  
  it "should clear old cached values when prepared" do
    prepare(:total_pages => 1)
    @renderer.send(:total_pages).should == 1
    # prepare with different object:
    prepare(:total_pages => 2)
    @renderer.send(:total_pages).should == 2
  end
  
  it "should have pagination definition" do
    prepare({ :total_pages => 1 }, :page_links => true)
    @renderer.pagination.should == [:previous_page, 1, :next_page]
  end
  
  describe "visible page numbers" do
    it "should calculate windowed visible links" do
      prepare({ :page => 6, :total_pages => 11 }, :inner_window => 1, :outer_window => 1)
      showing_pages 1, 2, :gap, 5, 6, 7, :gap, 10, 11
    end
  
    it "should eliminate small gaps" do
      prepare({ :page => 6, :total_pages => 11 }, :inner_window => 2, :outer_window => 1)
      # pages 4 and 8 appear instead of the gap
      showing_pages 1..11
    end
    
    it "should support having no windows at all" do
      prepare({ :page => 4, :total_pages => 7 }, :inner_window => 0, :outer_window => 0)
      showing_pages 1, :gap, 4, :gap, 7
    end
    
    it "should adjust upper limit if lower is out of bounds" do
      prepare({ :page => 1, :total_pages => 10 }, :inner_window => 2, :outer_window => 1)
      showing_pages 1, 2, 3, 4, 5, :gap, 9, 10
    end
    
    it "should adjust lower limit if upper is out of bounds" do
      prepare({ :page => 10, :total_pages => 10 }, :inner_window => 2, :outer_window => 1)
      showing_pages 1, 2, :gap, 6, 7, 8, 9, 10
    end
    
    def showing_pages(*pages)
      pages = pages.first.to_a if Array === pages.first or Range === pages.first
      @renderer.send(:windowed_page_numbers).should == pages
    end
  end
  
  protected

    def collection(params = {})
      if params[:total_pages]
        params[:per_page] = 1
        params[:total_entries] = params[:total_pages]
      end
      WillPaginate::Collection.new(params[:page] || 1, params[:per_page] || 30, params[:total_entries])
    end

    def prepare(collection_options, options = {})
      @renderer.prepare(collection(collection_options), options)
    end
  
end
