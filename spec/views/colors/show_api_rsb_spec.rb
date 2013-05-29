require File.expand_path('../../../spec_helper', __FILE__)

describe 'timelines/colors/show.api.rsb' do
  before do
    view.extend TimelinesHelper
  end

  before do
    params[:format] = 'xml'
  end

  describe 'with an assigned color' do
    let(:color) { FactoryGirl.build(:color) }

    it 'renders a color document' do
      assign(:color, color)

      render

      response.should have_selector('color', :count => 1)
    end

    it 'renders the _color template once' do
      assign(:color, color)

      view.should_receive(:render).once.with(hash_including(:partial => '/timelines/colors/color.api')).and_return('')

      # in order to enable calling the original render method
      # despite should_receive expectations
      view.should_receive(:render).once.with(hash_including(:template => "timelines/colors/show"), {})
                                  .and_call_original

      render
    end

    it 'passes the color as local var to the partial' do
      assign(:color, color)

      view.should_receive(:render).once.with(hash_including(:object => color)).and_return('')

      # in order to enable calling the original render method
      # despite should_receive expectations
      view.should_receive(:render).once.with(hash_including(:template => "timelines/colors/show"), {})
                                  .and_call_original

      render
    end
  end
end
