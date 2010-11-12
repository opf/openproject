require 'spec_helper'
require 'xls_report/issues_controller_patch'

describe IssuesController, "rendering to xls" do
  
  it "should respond with the xls if requested in the index" do
    pending
    params_from(:get, "/hello/world").should == {:controller => "hello", :action => "world"}
    render :action => :index
    response.should be_success
  end
  
  it "should not respond with the xls if requested in a detail view" do
    pending
    render :action => :show
    response.should_not be_success
  end
  
  it "should generate xls from issues" do
    pending
  end
  
end