require File.expand_path('../../spec_helper', __FILE__)

describe Timelines::TimelinesPlanningElementJournalsController do
  let(:project) { FactoryGirl.create(:project, :is_public => false) }

  describe 'index.xml' do
    def fetch
      planning_element = FactoryGirl.create(:timelines_planning_element,
                                        :project_id => project.id)

      get 'index', :project_id          => project.identifier,
                   :planning_element_id => planning_element.id,
                   :format              => 'xml'
    end
    let(:permission) { :view_planning_elements }

    it_should_behave_like "a controller action which needs project permissions"
  end
end

