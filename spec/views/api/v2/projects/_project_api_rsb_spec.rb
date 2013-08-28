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

require File.expand_path('../../../../../spec_helper', __FILE__)

describe 'api/v2/projects/_project.api' do
  before do
    view.extend TimelinesHelper
  end

  # added to pass in locals
  def render
    params[:format] = 'xml'
    super(:partial => 'api/v2/projects/project.api', :object => project)
  end

  describe 'with an assigned project' do
    let(:project) { FactoryGirl.build(:project, :id => 1,
                                      :identifier => 'awesometastic_project',
                                      :name => 'Awesometastic Project',
                                      :description => 'This project is awesometastic',
                                      :created_on => Time.parse('Thu Jan 06 12:35:00 +0100 2011'),
                                      :updated_on => Time.parse('Fri Jan 07 12:35:00 +0100 2011')) }


    it 'renders a project node' do
      render

      response.should have_selector('project', :count => 1)
    end

    describe 'project node' do
      it 'contains an id element containing the project id' do
        render

        response.should have_selector('project id', :text => '1')
      end

      it 'contains an identifier element containing the project identifier' do
        render

        response.should have_selector('project identifier', :text => 'awesometastic_project')
      end

      it 'contains a name element containing the project name' do
        render

        response.should have_selector('project name', :text => 'Awesometastic Project')
      end

      it 'contains a description element containing the project description' do
        render

        response.should have_selector('project description', :text => 'This project is awesometastic')
      end

      it 'does not contain a project_type element' do
        render

        response.should_not have_selector('project project_type')
      end

      it 'does not contain a planning_element_types element' do
        render

        response.should_not have_selector('project planning_element_types')
      end

      it 'does not contain a project_associations element' do
        render

        response.should_not have_selector('project project_associations')
      end

      it 'does not contain a parent element' do
        render

        response.should_not have_selector('project parent')
      end

      it 'does not contain a responsible element' do
        render

        response.should_not have_selector('project responsible')
      end

      it 'contains a created_on element containing the project created_on in UTC in ISO 8601' do
        render

        response.should have_selector('project created_on', :text => '2011-01-06T11:35:00Z')
      end

      it 'contains an updated_on element containing the project updated_on in UTC in ISO 8601' do
        render

        response.should have_selector('project updated_on', :text => '2011-01-07T11:35:00Z')
      end
    end
  end

  describe 'with a project having a parent project' do
    let(:parent_project) { FactoryGirl.create(:project, :id => 102, :name => 'Parent', :identifier => 'parent') }
    let(:project) { FactoryGirl.create(:project).tap { |p| p.move_to_child_of(parent_project.id)} }

    describe 'project node' do
      it 'contains a parent element with name and id attributes' do
        render

        response.should have_selector('project parent[name=Parent][id="102"][identifier=parent]', :count => 1)
      end
    end
  end

  describe 'with a project having an invisible parent project' do
    let(:parent_project) { FactoryGirl.create(:project, :id => 103, :name => 'Parent', :identifier => 'parent', :is_public => false) }
    let(:project) { FactoryGirl.create(:project).tap { |p| p.move_to_child_of(parent_project.id)} }

    describe 'project node' do
      it 'does not contain a parent element' do
        render

        response.should_not have_selector('project parent')
      end
    end
  end

  describe 'with a project having an invisible parent project and a visible grand-parent' do
    let(:grand_parent_project) { FactoryGirl.create(:project,
                                                :name => 'Grand-Parent',
                                                :identifier => 'granny') }
    let(:parent_project)       { FactoryGirl.create(:project,
                                                :name => 'Parent',
                                                :identifier => 'parent',
                                                :is_public => false).tap { |p| p.move_to_child_of(grand_parent_project.id) } }
    let(:project)              { FactoryGirl.create(:project).tap { |p| p.move_to_child_of(parent_project.id)} }

    describe 'project node' do
      it 'contains a parent element with name and id attributes of the grand parent' do
        render

        response.should have_selector("project parent[name=Grand-Parent][id='#{grand_parent_project.id}'][identifier=granny]", :count => 1)
      end
    end
  end

  describe 'with a project having a responsible' do
    let(:responsible) { FactoryGirl.create(:user,
                                       :id => 100,
                                       :firstname => 'Project',
                                       :lastname => 'Manager') }

    let(:project) { FactoryGirl.create(:project,
                                   :responsible_id => responsible.id) }

    describe 'project node' do
      it 'contains a responsible node containing the responsible\'s id and name' do
        render

        response.should have_selector('project responsible[id="100"][name="Project Manager"]')
      end
    end
  end

  describe 'with a project having a project type' do
    let(:project_type) { FactoryGirl.build(:project_type, :id => 100, :name => 'Awesometastic') }

    let(:project) { FactoryGirl.build(:project, :project_type_id => project_type.tap { |p| p.save! }.id) }

    describe 'project node' do
      it 'contains a project_type element with name and id attributes' do
        render

        response.should have_selector('project project_type[name=Awesometastic][id="100"]', :count => 1)
      end
    end
  end

  describe 'with a project having 3 enabled planning element types' do
    let(:color)        { FactoryGirl.create(:color) }
    let(:project)      { FactoryGirl.create(:project) }

    before do
      types = [
        FactoryGirl.create(:type, :color_id => color.id),
        FactoryGirl.create(:type, :color_id => color.id),
        FactoryGirl.create(:type, :color_id => color.id)
      ]
      project.types = types
      project.save
    end

    describe 'project node' do
      it 'contains a planning_element_types element of type array with a size of 3' do
        render

        response.should have_selector('project planning_element_types[type=array][size="3"]', :count => 1)
      end

      describe 'planning_element_types node' do
        it 'contains 3 planning_element_type elements having id and name attributes' do
          render

          response.should have_selector('project planning_element_types planning_element_type', :count => 3) do
            with_tag 'id'
            with_tag 'name'
            with_tag 'color[id][name][hexcode]'
            with_tag 'is_milestone'
          end
        end
      end
    end
  end

  describe 'with a project having project_associations' do
    let(:project) { FactoryGirl.create(:project) }

    before do
      FactoryGirl.create(:project_association,
                         :project_a_id => project.id,
                         :project_b_id => FactoryGirl.create(:project, :is_public => true).id)
      FactoryGirl.create(:project_association,
                         :project_b_id => project.id,
                         :project_a_id => FactoryGirl.create(:project, :is_public => true).id)

      # Adding invisible association to make sure, that it is not included in the output
      FactoryGirl.create(:project_association,
                         :project_a_id => project.id,
                         :project_b_id => FactoryGirl.create(:project, :is_public => false).id)
    end

    describe 'project node' do
      it 'contains a project_associations element of type array with a size of 2' do
        render

        response.should have_selector('project project_associations[type=array][size="2"]', :count => 1)
      end

      describe 'project_associations node' do
        it 'contains 2 project_associations elements having id and name attributes' do
          render

          response.should have_selector('project project_associations project_association[id]', :count => 2)
        end
      end
    end
  end
end
