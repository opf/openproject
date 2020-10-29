require 'spec_helper'

if !ENV['SKIP_NONRAILS_TESTS']
  require 'will_paginate/sequel'
  require File.expand_path('../sequel_test_connector', __FILE__)
  sequel_loaded = true
else
  sequel_loaded = false
end

describe Sequel::Dataset::Pagination, 'extension' do
  
  class Car < Sequel::Model
    self.dataset = dataset.extension(:pagination)
  end

  it "should have the #paginate method" do
    Car.dataset.should respond_to(:paginate)
  end

  it "should NOT have the #paginate_by_sql method" do
    Car.dataset.should_not respond_to(:paginate_by_sql)
  end

  describe 'pagination' do
    before(:all) do
      Car.create(:name => 'Shelby', :notes => "Man's best friend")
      Car.create(:name => 'Aston Martin', :notes => "Woman's best friend")
      Car.create(:name => 'Corvette', :notes => 'King of the Jungle')
    end

    it "should imitate WillPaginate::Collection" do
      result = Car.dataset.paginate(1, 2)
      
      result.should_not be_empty
      result.size.should == 2
      result.length.should == 2
      result.total_entries.should == 3
      result.total_pages.should == 2
      result.per_page.should == 2
      result.current_page.should == 1
    end
    
    it "should perform" do
      Car.dataset.paginate(1, 2).all.should == [Car[1], Car[2]]
    end

    it "should be empty" do
      result = Car.dataset.paginate(3, 2)
      result.should be_empty
    end
    
    it "should perform with #select and #order" do
      result = Car.select(Sequel.lit("name as foo")).order(:name).paginate(1, 2).all
      result.size.should == 2
      result.first.values[:foo].should == "Aston Martin"
    end

    it "should perform with #filter" do
      results = Car.filter(:name => 'Shelby').paginate(1, 2).all
      results.size.should == 1
      results.first.should == Car.find(:name => 'Shelby')
    end
  end

end if sequel_loaded
