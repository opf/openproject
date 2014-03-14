require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CostReportsController do
  include OpenProject::Reporting::PluginSpecHelper

  let(:user) { FactoryGirl.build(:user) }
  let(:project) { FactoryGirl.build(:valid_project) }

  describe "GET show" do
    before(:each) do
      is_member project, user, [:view_cost_entries]
      User.stub!(:current).and_return(user)
    end

    describe "WHEN providing invalid units
              WHEN having the view_cost_entries permission" do
      before do
        get :show, :id => 1, :unit => -1
      end

      it "should respond with a 404 error" do
        response.code.should eql("404")
      end
    end
  end
end
