require File.expand_path('../../../spec_helper', __FILE__)

describe 'timelines/project_types/show.api.rsb' do
  before do
    view.extend TimelinesHelper
  end

  before do
    params[:format] = 'xml'
  end

  describe 'with an assigned project type' do
    let(:project_type) { FactoryGirl.build(:project_type) }

    it 'renders a project_type document' do
      assign(:project_type, project_type)

      render

      response.should have_selector('project_type', :count => 1)
    end

    it 'renders the _project_type template once' do
      assign(:project_type, project_type)

      view.should_receive(:render).once.with(hash_including(:partial => '/timelines/project_types/project_type.api')).and_return('')

      # just to be able to render the speced template despite the should receive expectation above
      view.should_receive(:render).once.with({ :template=>"timelines/project_types/show",
                                               :handlers=>["rsb"],
                                               :formats=>["api"] },
                                             {})
                                  .and_call_original

      render
    end

    it 'passes the project type as local var to the partial' do
      assign(:project_type, project_type)

      view.should_receive(:render).once.with(hash_including(:object => project_type)).and_return('')

      # just to be able to render the speced template despite the should receive expectation above
      view.should_receive(:render).once.with({ :template=>"timelines/project_types/show",
                                               :handlers=>["rsb"],
                                               :formats=>["api"] },
                                             {})
                                  .and_call_original

      render
    end
  end
end
