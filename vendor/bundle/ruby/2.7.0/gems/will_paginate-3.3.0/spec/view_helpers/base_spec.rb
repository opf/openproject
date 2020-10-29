require 'spec_helper'
require 'will_paginate/view_helpers'
require 'will_paginate/array'
require 'active_support'
require 'active_support/core_ext/string/inflections'
require 'active_support/inflections'

describe WillPaginate::ViewHelpers do

  before(:all) do
    # make sure default translations aren't loaded
    I18n.load_path.clear
    I18n.enforce_available_locales = false
  end

  before(:each) do
    I18n.reload!
  end

  include WillPaginate::ViewHelpers
  
  describe "will_paginate" do
    it "should render" do
      collection = WillPaginate::Collection.new(1, 2, 4)
      renderer   = mock 'Renderer'
      renderer.expects(:prepare).with(collection, instance_of(Hash), self)
      renderer.expects(:to_html).returns('<PAGES>')
      
      will_paginate(collection, :renderer => renderer).should == '<PAGES>'
    end
    
    it "should return nil for single-page collections" do
      collection = mock 'Collection', :total_pages => 1
      will_paginate(collection).should be_nil
    end

    it "should call html_safe on result" do
      collection = WillPaginate::Collection.new(1, 2, 4)

      html = mock 'HTML'
      html.expects(:html_safe).returns(html)
      renderer = mock 'Renderer'
      renderer.stubs(:prepare)
      renderer.expects(:to_html).returns(html)

      will_paginate(collection, :renderer => renderer).should eql(html)
    end
  end

  describe "pagination_options" do
    let(:pagination_options) { WillPaginate::ViewHelpers.pagination_options }

    it "deprecates setting :renderer" do
      begin
        lambda {
          pagination_options[:renderer] = 'test'
        }.should have_deprecation("pagination_options[:renderer] shouldn't be set")
      ensure
        pagination_options.delete :renderer
      end
    end
  end
  
  describe "page_entries_info" do
    before :all do
      @array = ('a'..'z').to_a
    end

    def info(params, options = {})
      collection = Hash === params ? @array.paginate(params) : params
      page_entries_info collection, {:html => false}.merge(options)
    end

    it "should display middle results and total count" do
      info(:page => 2, :per_page => 5).should == "Displaying strings 6 - 10 of 26 in total"
    end

    it "uses translation if available" do
      translation :will_paginate => {
        :page_entries_info => {:multi_page => 'Showing %{from} - %{to}'}
      }
      info(:page => 2, :per_page => 5).should == "Showing 6 - 10"
    end

    it "uses specific translation if available" do
      translation :will_paginate => {
        :page_entries_info => {:multi_page => 'Showing %{from} - %{to}'},
        :string => { :page_entries_info => {:multi_page => 'Strings %{from} to %{to}'} }
      }
      info(:page => 2, :per_page => 5).should == "Strings 6 to 10"
    end

    it "should output HTML by default" do
      info({ :page => 2, :per_page => 5 }, :html => true).should ==
        "Displaying strings <b>6&nbsp;-&nbsp;10</b> of <b>26</b> in total"
    end

    it "should display shortened end results" do
      info(:page => 7, :per_page => 4).should include_phrase('strings 25 - 26')
    end

    it "should handle longer class names" do
      collection = @array.paginate(:page => 2, :per_page => 5)
      model = stub('Class', :name => 'ProjectType', :to_s => 'ProjectType')
      collection.first.stubs(:class).returns(model)
      info(collection).should include_phrase('project types')
    end

    it "should adjust output for single-page collections" do
      info(('a'..'d').to_a.paginate(:page => 1, :per_page => 5)).should == "Displaying all 4 strings"
      info(['a'].paginate(:page => 1, :per_page => 5)).should == "Displaying 1 string"
    end
  
    it "should display 'no entries found' for empty collections" do
      info([].paginate(:page => 1, :per_page => 5)).should == "No entries found"
    end

    it "uses model_name.human when available" do
      name = stub('model name', :i18n_key => :flower_key)
      name.expects(:human).with(:count => 1).returns('flower')
      model = stub('Class', :model_name => name)
      collection = [1].paginate(:page => 1)

      info(collection, :model => model).should == "Displaying 1 flower"
    end

    it "uses custom translation instead of model_name.human" do
      name = stub('model name', :i18n_key => :flower_key)
      name.expects(:human).never
      model = stub('Class', :model_name => name)
      translation :will_paginate => {:models => {:flower_key => 'tulip'}}
      collection = [1].paginate(:page => 1)

      info(collection, :model => model).should == "Displaying 1 tulip"
    end

    private

    def translation(data)
      I18n.backend.store_translations(:en, data)
    end
  end
end
