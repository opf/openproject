require File.dirname(__FILE__) + '/../spec_helper'

describe MyProjectsOverviewsController do
  before :each do
    @controller.stub!(:set_localization)
    @controller.should_receive(:authorize)

    @role = FactoryGirl.create(:non_member)
    @user = FactoryGirl.create(:admin)

    User.stub!(:current).and_return @user

    @params = {}
  end

  let(:project) { FactoryGirl.create(:project) }

  describe 'index' do
    let(:params) { { "id" => project.id.to_s } }

    describe "WHEN calling the page" do
      render_views

      before do
        get 'index', params
      end

      it 'renders the overview page' do
        response.should be_success
        response.should render_template 'index'
      end
    end

    describe "WHEN calling the page
              WHEN providing a jump parameter" do

      before do
        params["jump"] = "issues"
        get 'index', params
      end

      it { response.should redirect_to({ :controller => "issues", :action => "index", :project_id => project }) }
    end
  end
end
