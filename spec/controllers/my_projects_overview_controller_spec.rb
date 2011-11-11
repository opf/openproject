require File.dirname(__FILE__) + '/../spec_helper'

describe ProjectsController do
  before :each do
    @controller.stub!(:set_localization)

    @role = Factory.create(:non_member)
    @user = Factory.create(:admin)

    User.stub!(:current).and_return @user

    @params = {}
  end

  describe 'index' do
    integrate_views

    before do
      @project = Factory.create(:project)
      @params[:id] = @project.id
    end

    it 'renders the overview page' do
      get 'index', @params
      response.should be_success
      response.should render_template 'index'
    end
  end
end
