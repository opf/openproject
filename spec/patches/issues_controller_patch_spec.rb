require 'spec_helper'

describe IssuesController, "rendering to xls", :type => :controller do
  let(:current_user) { FactoryGirl.create(:admin) }

  before do
    User.stub(:current).and_return current_user
  end

  describe "should respond with the xls if requested in the index" do
    let!(:issue) { FactoryGirl.create(:issue) }

    before do
      get('index', :format => 'xls', :project_id => issue.project_id)
    end

    it 'should respond with 200 OK' do
      response.response_code.should == 200
    end

    it 'should have a length > 100 bytes' do
      response.body.length.should > 100
    end

    context 'the mime type' do
      it { response.header['Content-Type'].should == 'application/vnd.ms-excel' }
    end
  end
end
