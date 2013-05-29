require File.expand_path('../../../spec_helper', __FILE__)

describe 'timelines/planning_elements/destroy.api.rsb' do
  before do
    view.extend TimelinesHelper
    view.extend TimelinesPlanningElementsHelper
  end

  before do
    view.stub(:include_journals?).and_return(false)
    view.stub(:include_scenarios?).and_return(false)

    params[:format] = 'xml'
  end

  let(:planning_element) { FactoryGirl.build(:planning_element) }

  describe 'with an assigned planning element' do
    it 'renders a planning_element document' do
      assign(:planning_element, planning_element)

      render

      response.should have_selector('planning_element', :count => 1)
    end

    it 'calls the render_planning_element helper once' do
      assign(:planning_element, planning_element)

      view.should_receive(:render_planning_element).once.and_return('')

      render
    end

    it 'passes the planning element as local var to the helper' do
      assign(:planning_element, planning_element)

      view.should_receive(:render_planning_element).once.with(anything, planning_element).and_return('')

      render
    end
  end
end
