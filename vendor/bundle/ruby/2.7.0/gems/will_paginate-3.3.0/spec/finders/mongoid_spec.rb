require 'spec_helper'

if !ENV['SKIP_NONRAILS_TESTS']
  if defined?(Rails)
    old_rails = Rails
    # Mongoid sees the `Rails` constant and then proceeds to `require "rails"`
    # from its railtie. This tricks it into believing there is no Rails.
    Object.send(:remove_const, :Rails)
  end
  require 'will_paginate/mongoid'
  Object.send(:const_set, :Rails, old_rails) if old_rails

  Mongo::Logger.logger.level = Logger::INFO

  Mongoid.connect_to 'will_paginate_test'
  class MongoidModel
    include Mongoid::Document
  end

  mongoid_loaded = true
else
  mongoid_loaded = false
end

describe WillPaginate::Mongoid do
  before(:all) do
    MongoidModel.delete_all
    4.times { MongoidModel.create! }
  end

  let(:criteria) { MongoidModel.criteria }

  describe "#page" do
    it "should forward to the paginate method" do
      criteria.expects(:paginate).with(:page => 2).returns("itself")
      criteria.page(2).should == "itself"
    end

    it "should not override per_page if set earlier in the chain" do
      criteria.paginate(:per_page => 10).page(1).per_page.should == 10
      criteria.paginate(:per_page => 20).page(1).per_page.should == 20
    end
  end

  describe "#per_page" do
    it "should set the limit if given an argument" do
      criteria.per_page(10).options[:limit].should == 10
    end

    it "should return the current limit if no argument is given" do
      criteria.per_page.should == nil
      criteria.per_page(10).per_page.should == 10
    end

    it "should be interchangable with limit" do
      criteria.limit(15).per_page.should == 15
    end

    it "should be nil'able" do
      criteria.per_page(nil).per_page.should be_nil
    end
  end

  describe "#paginate" do
    it "should use criteria" do
      criteria.paginate.should be_instance_of(::Mongoid::Criteria)
    end

    it "should not override page number if set earlier in the chain" do
      criteria.page(3).paginate.current_page.should == 3
    end

    it "should limit according to per_page parameter" do
      criteria.paginate(:per_page => 10).options.should include(:limit => 10)
    end

    it "should skip according to page and per_page parameters" do
      criteria.paginate(:page => 2, :per_page => 5).options.should include(:skip => 5)
    end

    specify "first fallback value for per_page option is the current limit" do
      criteria.limit(12).paginate.options.should include(:limit => 12)
    end

    specify "second fallback value for per_page option is WillPaginate.per_page" do
      criteria.paginate.options.should include(:limit => WillPaginate.per_page)
    end

    specify "page should default to 1" do
      criteria.paginate.options.should include(:skip => 0)
    end

    it "should convert strings to integers" do
      criteria.paginate(:page => "2", :per_page => "3").options.should include(:limit => 3)
    end

    describe "collection compatibility" do
      describe "#total_count" do
        it "should be calculated correctly" do
          criteria.paginate(:per_page => 1).total_entries.should == 4
          criteria.paginate(:per_page => 3).total_entries.should == 4
        end

        it "should be cached" do
          criteria.expects(:count).once.returns(123)
          criteria.paginate
          2.times { criteria.total_entries.should == 123 }
        end
      end

      it "should calculate total_pages" do
        criteria.paginate(:per_page => 1).total_pages.should == 4
        criteria.paginate(:per_page => 3).total_pages.should == 2
        criteria.paginate(:per_page => 10).total_pages.should == 1
      end

      it "should return per_page" do
        criteria.paginate(:per_page => 1).per_page.should == 1
        criteria.paginate(:per_page => 5).per_page.should == 5
      end

      describe "#current_page" do
        it "should return current_page" do
          criteria.paginate(:page => 1).current_page.should == 1
          criteria.paginate(:page => 3).current_page.should == 3
        end

        it "should be casted to PageNumber" do
          page = criteria.paginate(:page => 1).current_page
          (page.instance_of? WillPaginate::PageNumber).should be
        end
      end

      it "should return offset" do
        criteria.paginate(:page => 1).offset.should == 0
        criteria.paginate(:page => 2, :per_page => 5).offset.should == 5
        criteria.paginate(:page => 3, :per_page => 10).offset.should == 20
      end

      it "should not pollute plain mongoid criterias" do
        %w(total_entries total_pages current_page).each do |method|
          criteria.should_not respond_to(method)
        end
      end
    end
  end
end if mongoid_loaded
