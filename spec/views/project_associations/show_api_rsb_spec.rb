require File.expand_path('../../../spec_helper', __FILE__)

describe 'timelines/project_associations/show.api.rsb' do
  before do
    view.extend TimelinesHelper
  end

  before do
    params[:format] = 'xml'
  end

  describe 'with an assigned project_association' do
    let(:project_association) { FactoryGirl.build(:project_association) }

    it 'renders a project_association document' do
      assign(:project_association, project_association)

      render

      response.should have_selector('project_association', :count => 1)
    end

    it 'renders the _project_association template once' do
      assign(:project_association, project_association)

      view.should_receive(:render).once.with(hash_including(:partial => '/timelines/project_associations/project_association.api')).and_return('')

      # just to render the speced template despite the should receive expectations above
      view.should_receive(:render).once.with({:template=>"timelines/project_associations/show", :handlers=>["rsb"], :formats=>["api"]}, {}).and_call_original

      render
    end

    it 'passes the project_association as local var to the partial' do
      assign(:project_association, project_association)

      view.should_receive(:render).once.with(hash_including(:object => project_association)).and_return('')

      # just to render the speced template despite the should receive expectations above
      view.should_receive(:render).once.with({:template=>"timelines/project_associations/show", :handlers=>["rsb"], :formats=>["api"]}, {}).and_call_original

      render
    end
  end
end
