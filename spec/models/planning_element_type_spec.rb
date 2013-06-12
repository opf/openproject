#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path('../../spec_helper', __FILE__)

describe PlanningElementType do
  describe '- Relations ' do
    describe '#planning_elements' do
      it 'can read planning_elements w/ the help of the has_many association' do
        planning_element_type = FactoryGirl.create(:planning_element_type)
        planning_element      = FactoryGirl.create(:planning_element,
                                               :planning_element_type_id => planning_element_type.id)

        planning_element_type.reload

        planning_element_type.planning_elements.size.should  == 1
        planning_element_type.planning_elements.first.should == planning_element
      end

      it 'nullifies dependent planning_elements' do
        planning_element_type = FactoryGirl.create(:planning_element_type)
        planning_element      = FactoryGirl.create(:planning_element,
                                               :planning_element_type_id => planning_element_type.id)

        planning_element_type.reload
        planning_element_type.destroy

        planning_element.reload
        planning_element.planning_element_type_id.should be_nil
      end
    end

    describe '#enabled_planning_element_types' do
      it 'can read enabled_planning_element_types w/ the help of the has_many association' do
        planning_element_type         = FactoryGirl.create(:planning_element_type)
        enabled_planning_element_type = FactoryGirl.create(:enabled_planning_element_type,
                                                       :planning_element_type_id => planning_element_type.id)

        planning_element_type.reload

        planning_element_type.enabled_planning_element_types.size.should  == 1
        planning_element_type.enabled_planning_element_types.first.should == enabled_planning_element_type
      end

      it 'deletes dependent enabled_planning_element_types' do
        planning_element_type         = FactoryGirl.create(:planning_element_type)
        enabled_planning_element_type = FactoryGirl.create(:enabled_planning_element_type,
                                                       :planning_element_type_id => planning_element_type.id)

        planning_element_type.reload
        planning_element_type.destroy

        expect { enabled_planning_element_type.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe '#projects' do
      it 'can read projects w/ the help of the has_many-through association' do
        planning_element_type         = FactoryGirl.create(:planning_element_type)
        project                       = FactoryGirl.create(:project)
        enabled_planning_element_type = FactoryGirl.create(:enabled_planning_element_type,
                                                       :project_id               => project.id,
                                                       :planning_element_type_id => planning_element_type.id)

        planning_element_type.reload

        planning_element_type.projects.size.should  == 1
        planning_element_type.projects.first.should == project
      end
    end

    describe '#default_planning_element_types' do
      it 'can read disabled_planning_element_types w/ the help of the has_many association' do
        planning_element_type         = FactoryGirl.create(:planning_element_type)
        default_planning_element_type = FactoryGirl.create(:default_planning_element_type,
                                                       :planning_element_type_id => planning_element_type.id)

        planning_element_type.reload

        planning_element_type.default_planning_element_types.size.should  == 1
        planning_element_type.default_planning_element_types.first.should == default_planning_element_type
      end

      it 'deletes dependent default_planning_element_types' do
        planning_element_type         = FactoryGirl.create(:planning_element_type)
        default_planning_element_type = FactoryGirl.create(:default_planning_element_type,
                                                       :planning_element_type_id => planning_element_type.id)

        planning_element_type.reload
        planning_element_type.destroy

        expect { default_planning_element_type.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe '#project_type' do
      it 'can read the project_type w/ the help of the has_many-through association' do
        project_type          = FactoryGirl.create(:project_type)
        planning_element_type         = FactoryGirl.create(:planning_element_type)
        default_planning_element_type = FactoryGirl.create(:default_planning_element_type,
                                                       :project_type_id          => project_type.id,
                                                       :planning_element_type_id => planning_element_type.id)

        planning_element_type.reload

        planning_element_type.project_types.size.should  == 1
        planning_element_type.project_types.first.should == project_type
      end
    end

    describe '#color' do
      it 'can read the color w/ the help of the belongs_to association' do
        color                 = FactoryGirl.create(:color)
        planning_element_type = FactoryGirl.create(:planning_element_type,
                                               :color_id => color.id)

        planning_element_type.reload

        planning_element_type.color.should == color
      end
    end
  end

  describe '- Validations ' do
    let(:attributes) {
      {:name => 'Planning Element Type No. 1'}
    }

    describe 'name' do
      it 'is invalid w/o a name' do
        attributes[:name] = nil
        planning_element_type = PlanningElementType.new(attributes)

        planning_element_type.should_not be_valid

        planning_element_type.errors[:name].should be_present
        planning_element_type.errors[:name].should == ["can't be blank"]
      end

      it 'is invalid w/ a name longer than 255 characters' do
        attributes[:name] = "A" * 500
        planning_element_type = PlanningElementType.new(attributes)

        planning_element_type.should_not be_valid

        planning_element_type.errors[:name].should be_present
        planning_element_type.errors[:name].should == ["is too long (maximum is 255 characters)"]
      end
    end

    describe 'in_aggregation' do
      it 'is invalid w/o the in_aggregation property' do
        attributes[:in_aggregation] = nil
        planning_element_type = PlanningElementType.new(attributes)

        planning_element_type.should_not be_valid

        planning_element_type.errors[:in_aggregation].should be_present
      end

      it 'is valid w/ in_aggregation set to true' do
        attributes[:in_aggregation] = true
        planning_element_type = PlanningElementType.new(attributes)

        planning_element_type.should be_valid
      end

      it 'is valid w/ in_aggregation set to false' do
        attributes[:in_aggregation] = false
        planning_element_type = PlanningElementType.new(attributes)

        planning_element_type.should be_valid
      end
    end

    describe 'is_default' do
      it 'is invalid w/o the is_default property' do
        attributes[:is_default] = nil
        planning_element_type = PlanningElementType.new(attributes)

        planning_element_type.should_not be_valid

        planning_element_type.errors[:is_default].should be_present
      end

      it 'is valid w/ is_default set to true' do
        attributes[:is_default] = true
        planning_element_type = PlanningElementType.new(attributes)

        planning_element_type.should be_valid
      end

      it 'is valid w/ is_default set to false' do
        attributes[:is_default] = false
        planning_element_type = PlanningElementType.new(attributes)

        planning_element_type.should be_valid
      end
    end

    describe 'is_milestone' do
      it 'is invalid w/o the is_milestone property' do
        attributes[:is_milestone] = nil
        planning_element_type = PlanningElementType.new(attributes)

        planning_element_type.should_not be_valid

        planning_element_type.errors[:is_milestone].should be_present
      end

      it 'is valid w/ is_milestone set to true' do
        attributes[:is_milestone] = true
        planning_element_type = PlanningElementType.new(attributes)

        planning_element_type.should be_valid
      end

      it 'is valid w/ is_milestone set to false' do
        attributes[:is_milestone] = false
        planning_element_type = PlanningElementType.new(attributes)

        planning_element_type.should be_valid
      end
    end
  end

  describe '#enabled_in?' do
    let(:planning_element_type) { FactoryGirl.create(:planning_element_type) }

    describe 'for nil' do
      it 'returns false' do
        planning_element_type.should_not be_enabled_in(nil)
      end
    end

    describe 'for projects' do
      let(:project) { FactoryGirl.create(:project) }

      describe 'when planning element type is enabled in given project' do
        before do
          project.planning_element_types << planning_element_type
        end

        it 'returns true' do
          planning_element_type.should be_enabled_in(project)
        end
      end

      describe 'when planning element type is not enabled in given project' do
        it 'returns false' do
          planning_element_type.should_not be_enabled_in(project)
        end
      end
    end

    describe 'for project types' do
      let(:project_type) { FactoryGirl.create(:project_type) }

      describe 'when planning element type is default in given project type' do
        before do
          project_type.planning_element_types << planning_element_type
        end

        it 'returns true' do
          planning_element_type.should be_enabled_in(project_type)
        end
      end

      describe 'when planning element type is not default in given project type' do
        it 'return false' do
          planning_element_type.should_not be_enabled_in(project_type)
        end
      end
    end
  end
end
