require 'spec_helper'

describe WorkPackagesController, "rendering to xls", :type => :controller do
  let(:current_user) { FactoryGirl.create(:admin) }
  let!(:work_package) { FactoryGirl.create(:work_package, :subject => '!SUBJECT!',
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

  describe 'empty result' do
    before do
      work_package.delete

      get 'index', :format => 'xls', :project_id => work_package.project_id
    end

    it 'should yield an empty XLS file' do
      expect(response.response_code).to be(200)

      f = Tempfile.new 'result.xls'
      begin
        f.binmode
        f.write response.body
      ensure
        f.close
      end

      require 'spreadsheet'

      sheet = Spreadsheet.open(f.path).worksheets.first
      expect(sheet.rows.size).to eq(1) # just the headers
    end
  end
end
