require File.expand_path('../../../spec_helper', __FILE__)

describe EnabledPlanningElementType do
  describe '- Relations ' do
    it 'can read the project w/ the help of the belongs_to association' do
      project                       = FactoryGirl.create(:project)
      enabled_planning_element_type = FactoryGirl.create(:enabled_planning_element_type,
                                                     :project_id => project.id)

      enabled_planning_element_type.reload

      enabled_planning_element_type.project.should == project
    end

    it 'can read the planning_element_type w/ the help of the belongs_to association' do
      planning_element_type         = FactoryGirl.create(:planning_element_type)
      enabled_planning_element_type = FactoryGirl.create(:enabled_planning_element_type,
                                                     :planning_element_type_id => planning_element_type.id)

      enabled_planning_element_type.reload

      enabled_planning_element_type.planning_element_type.should == planning_element_type
    end
  end
end
