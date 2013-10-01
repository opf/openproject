require 'spec_helper'

describe VersionsController do
  before do
    @controller.stub(:authorize)

#create a version assigned to a project
    @version = FactoryGirl.create(:version)
    @oldVersionName = @version.name
    @newVersionName = "NewVersionName"
#create another project
    @project = FactoryGirl.create(:project)
#todo is this necessary?
#    @project.reload
#create params to update version
    @params = {}
    @params[:id] = @version.id
    @params[:version] = { :name => @newVersionName }
  end

  describe 'update' do
    it 'does not allow to update versions from different projects' do
      @params[:project_id] = @project.id
      put 'update', @params
      @version.reload

      response.should redirect_to :controller => '/projects', :action => 'settings', :tab => 'versions', :id => @project
      @version.name.should == @oldVersionName
    end

    it 'allows to update versions from the version project' do
      @params[:project_id] = @version.project.id
      put 'update', @params
      @version.reload

      response.should redirect_to :controller => '/projects', :action => 'settings', :tab => 'versions', :id => @version.project
      @version.name.should == @newVersionName
    end
  end
end
