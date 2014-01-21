
require 'spec_helper'

describe TaskboardCardConfigurationsController do
  before do
    @controller.stub(:authorize)

    @default_config = FactoryGirl.create(:default_taskboard_card_configuration)
    @custom_config = FactoryGirl.create(:taskboard_card_configuration)

    @params = {}
  end

  describe 'Create' do
    it 'should let you create a configuration with all the values set' do
      @params[:taskboard_card_configuration] = {
        name: "Config 1",
        identifier: "config1",
        rows: "row1",
        per_page: 5,
        page_size: "A4",
        orientation: "landscape"
      }
      post 'create', @params

      response.should redirect_to :action => 'index'
      flash[:notice].should eql(I18n.t(:notice_successful_create))
    end

    it 'should not let you create an invalid configuration' do
      @params[:taskboard_card_configuration] = {
        name: "Config 1",
        identifier: "config1"
      }
      post 'create', @params

      response.should render_template('new')
    end
  end

  describe 'Update' do
    it 'should let you update a configuration' do
      @params[:id] = @custom_config.id
      @params[:taskboard_card_configuration] = { per_page: 4}
      put 'update', @params

      response.should redirect_to :action => 'index'
      flash[:notice].should eql(I18n.t(:notice_successful_update))
    end

    it 'should  not let you update an invalid configuration' do
      @params[:id] = @custom_config.id
      @params[:taskboard_card_configuration] = { per_page: "string"}
      put 'update', @params

      response.should render_template('edit')
    end
  end

  describe 'Delete' do
    it 'should let you delete a custom configuration' do
      @params[:id] = @custom_config.id
      delete 'destroy', @params

      response.should redirect_to :action => 'index'
      flash[:notice].should eql(I18n.t(:notice_successful_delete))
    end

    it 'should not let you delete the default configuration' do
      @params[:id] = @default_config.id
      delete 'destroy', @params

      response.should redirect_to :action => 'index'
      flash[:notice].should eql(I18n.t(:error_can_not_delete_taskboard_card_configuration))
    end
  end
end