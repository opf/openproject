require 'spec_helper'

describe IssuesController, "rendering to xls", :type => :controller do
  let(:current_user) { FactoryGirl.create(:admin) }
  let!(:work_package) { FactoryGirl.create(:issue, :subject => '!SUBJECT!',
                                                   :description => '!DESCRIPTION!') }

  before do
    User.stub(:current).and_return current_user
  end

  describe "should respond with the xls if requested in the index" do
    before do
      get('index', :format => 'xls', :project_id => work_package.project_id)
    end

    it 'should respond with 200 OK' do
      response.response_code.should == 200
    end

    it 'should have a length > 100 bytes' do
      response.body.length.should > 100
    end

    it 'should not contain a description' do
      response.body.should_not include('!DESCRIPTION!')
    end

    it 'should contain a subject' do
      response.body.should include('!SUBJECT!')
    end

    context 'the mime type' do
      it { response.header['Content-Type'].should == 'application/vnd.ms-excel' }
    end
  end

  context 'with descriptions' do
    before do
      get('index', :format => 'xls',
                   :project_id => work_package.project_id,
                   :show_descriptions => 'true')
    end

    it 'should respond with 200 OK' do
      response.response_code.should == 200
    end

    it 'should have a length > 100 bytes' do
      response.body.length.should > 100
    end

    it 'should contain a description' do
      response.body.should include('!DESCRIPTION!')
    end

    it 'should contain a subject' do
      response.body.should include('!SUBJECT!')
    end

    context 'the mime type' do
      it { response.header['Content-Type'].should == 'application/vnd.ms-excel' }
    end
  end
end
