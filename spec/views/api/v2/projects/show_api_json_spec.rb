#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path('../../../../../spec_helper', __FILE__)

describe 'api/v2/projects/show.api.rabl' do

  before do
    params[:format] = 'json'
  end

  let(:admin) {FactoryGirl.create(:admin)}
  let(:anonymous) { FactoryGirl.create(:anonymous)}


  describe 'with an assigned project' do

    let(:sample_type){FactoryGirl.build(:project_type, id: 1, name: "SampleType")}
    let(:sample_project) { FactoryGirl.build(:project, :id => 1,
                                      :project_type => sample_type,
                                      :project_type_id => 1,
                                      :identifier => 'project_1',
                                      :name => 'Project #1',
                                      :description => 'sample description',
                                      :created_on => Time.parse('Thu Jan 06 12:35:00 +0100 2011'),
                                      :updated_on => Time.parse('Fri Jan 07 12:35:00 +0100 2011')) }


    before do
      User.stub(:current).and_return(admin)

      assign(:project,  sample_project)
      render
    end

    subject { response.body }

    it 'renders a project document' do
      should have_json_path('project')
    end

    it 'renders the project-infos for an admin' do
      # admin is used to make the rights predictable
      expected_json = {id: 1,
                       name: "Project #1",
                       description: "sample description",
                       identifier: "project_1",
                       project_type_id: 1,
                       edit_planning_elements: true,
                       delete_planning_elements: true,
                       view_planning_elements: true,
                       project_type: { name: "SampleType"},
                       created_on: "2011-01-06T11:35:00Z",
                       updated_on: "2011-01-07T11:35:00Z" }.to_json

      should be_json_eql(expected_json).at_path('project')
    end

  end

  describe 'with a project having a parent project' do
    let(:parent_project) { FactoryGirl.create(:project, :id => 102, :name => 'Parent', :identifier => 'parent') }
    let(:project) { FactoryGirl.create(:project).tap { |p| p.move_to_child_of(parent_project.id)} }

    before do
      assign(:project, project)
      render
    end

    subject {response.body}

    describe 'project node' do
      it 'contains a parent element with name and id attributes' do
        expected_json = {id: 102, name: 'Parent', identifier: 'parent'}.to_json
        response.should be_json_eql(expected_json).at_path('project/parent')
      end
    end
  end

  describe 'with a project having an invisible parent project' do

    let(:parent_project) { FactoryGirl.create(:project, :id => 103, :name => 'Parent', :identifier => 'parent', :is_public => false) }
    let(:project) { FactoryGirl.create(:project).tap { |p| p.move_to_child_of(parent_project.id)} }

    before do
      User.stub(:current).and_return anonymous

      assign(:project, project)
      render
    end

    subject {response.body}

    it 'does not contain a parent element' do
      response.should_not have_json_path('project/parent')
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

    before do
      User.stub(:current).and_return anonymous

      assign(:project, project)
      render
    end

    subject {response.body}

    it 'contains a parent element with name and id attributes of the grand parent' do
      expected_json = {id: 102, name: 'Grand-Parent', identifier: 'granny'}.to_json
      response.should be_json_eql(expected_json).at_path('project/parent')
    end

  end

  describe 'with a project having a responsible' do
    let(:responsible) { FactoryGirl.create(:user,
                                           :id => 100,
                                           :firstname => 'Project',
                                           :lastname => 'Manager') }

    let(:project) { FactoryGirl.create(:project,
                                       :responsible_id => responsible.id) }

    before do
      assign(:project, project)
      render
    end

    subject{ response.body }

    it 'contains a responsible node containing the responsible\'s id and name' do
      expected_json = {id: 100, name: "Project Manager"}.to_json
      should be_json_eql(expected_json).at_path('project/responsible')
    end

  end

  describe 'with a project having a project type' do
    let(:project_type) { FactoryGirl.build(:project_type, :id => 100, :name => 'Sample ProjectType') }

    let(:project) { FactoryGirl.build(:project, :project_type_id => project_type.tap { |p| p.save! }.id) }

    before do
      assign(:project, project)
      render
    end

    subject{ response.body}

    it 'contains a project_type element with name and id attributes' do
      expected_json = {id: 100, name: 'Sample ProjectType'}.to_json
      should be_json_eql(expected_json).at_path('project/project_type')
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


end
