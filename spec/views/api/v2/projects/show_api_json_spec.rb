#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

describe 'api/v2/projects/show.api.rabl', type: :view do

  before do
    params[:format] = 'json'
  end

  let(:admin) { FactoryGirl.create(:admin) }
  let(:anonymous) { FactoryGirl.create(:anonymous) }

  describe 'with an assigned project' do

    let(:sample_type) { FactoryGirl.build(:project_type, id: 1, name: 'SampleType') }
    let(:sample_project) {
      FactoryGirl.build(:project, id: 1,
                                  project_type: sample_type,
                                  project_type_id: 1,
                                  identifier: 'project_1',
                                  name: 'Project #1',
                                  description: 'sample description',
                                  created_on: Time.parse('Thu Jan 06 12:35:00 +0100 2011'),
                                  updated_on: Time.parse('Fri Jan 07 12:35:00 +0100 2011'))
    }

    before do
      allow(User).to receive(:current).and_return(admin)

      assign(:project,  sample_project)
      render
    end

    subject { response.body }

    it 'renders a project document' do
      is_expected.to have_json_path('project')
    end

    it 'renders the project-infos for an admin' do
      # admin is used to make the rights predictable
      expected_json = { id: 1,
                        name: 'Project #1',
                        description: 'sample description',
                        identifier: 'project_1',
                        project_type_id: 1,
                        permissions: {
                          edit_planning_elements: true,
                          delete_planning_elements: true,
                          view_planning_elements: true },
                        custom_fields: [],
                        project_type: { name: 'SampleType' },
                        created_on: '2011-01-06T11:35:00Z',
                        updated_on: '2011-01-07T11:35:00Z' }.to_json

      is_expected.to be_json_eql(expected_json).at_path('project')
    end

  end

  describe 'with a project having a parent project' do
    let(:parent_project) { FactoryGirl.create(:public_project, name: 'Parent', identifier: 'parent') }
    let(:project) { FactoryGirl.create(:project).tap { |p| p.move_to_child_of(parent_project.id) } }

    before do
      assign(:project, project)
      render
    end

    subject { response.body }

    describe 'project node' do
      it 'contains a parent element with name and id attributes' do
        expected_json = { id: parent_project.id, name: 'Parent', identifier: 'parent' }.to_json
        expect(response).to be_json_eql(expected_json).at_path('project/parent')
      end
    end
  end

  describe 'with a project having an invisible parent project' do

    let(:parent_project) { FactoryGirl.create(:project, name: 'Parent', identifier: 'parent', is_public: false) }
    let(:project) { FactoryGirl.create(:project).tap { |p| p.move_to_child_of(parent_project.id) } }

    before do
      allow(User).to receive(:current).and_return anonymous

      assign(:project, project)
      render
    end

    subject { response.body }

    it 'does not contain a parent element' do
      expect(response).not_to have_json_path('project/parent')
    end

  end

  describe 'with a project having an invisible parent project and a visible grand-parent' do
    let(:grand_parent_project) {
      FactoryGirl.create(:public_project,
                         name: 'Grand-Parent',
                         identifier: 'granny')
    }
    let(:parent_project)       {
      FactoryGirl.create(:project,
                         name: 'Parent',
                         identifier: 'parent',
                         is_public: false).tap { |p| p.move_to_child_of(grand_parent_project.id) }
    }
    let(:project)              { FactoryGirl.create(:project).tap { |p| p.move_to_child_of(parent_project.id) } }

    before do
      allow(User).to receive(:current).and_return anonymous

      assign(:project, project)
      render
    end

    subject { response.body }

    it 'contains a parent element with name and id attributes of the grand parent' do
      expected_json = { id: parent_project.id, name: 'Grand-Parent', identifier: 'granny' }.to_json
      expect(response).to be_json_eql(expected_json).at_path('project/parent')
    end

  end

  describe 'with a project having a responsible' do
    let(:responsible) {
      FactoryGirl.create(:user,
                         firstname: 'Project',
                         lastname: 'Manager')
    }

    let(:project) {
      FactoryGirl.create(:project,
                         responsible_id: responsible.id)
    }

    before do
      assign(:project, project)
      render
    end

    subject { response.body }

    it 'contains a responsible node containing the responsible\'s id and name' do
      expected_json = { id: responsible.id, name: 'Project Manager' }.to_json
      is_expected.to be_json_eql(expected_json).at_path('project/responsible')
    end

  end

  describe 'with a project having a project type' do
    let(:project_type) { FactoryGirl.build(:project_type, id: 100, name: 'Sample ProjectType') }

    let(:project) { FactoryGirl.build(:project, project_type_id: project_type.tap(&:save!).id) }

    before do
      assign(:project, project)
      render
    end

    subject { response.body }

    it 'contains a project_type element with name and id attributes' do
      expected_json = { id: 100, name: 'Sample ProjectType' }.to_json
      is_expected.to be_json_eql(expected_json).at_path('project/project_type')
    end

  end

  describe 'with a project having 3 enabled planning element types' do
    let(:color)        { FactoryGirl.create(:color, hexcode: '#ff0000', name: 'red') }
    let(:project)      { FactoryGirl.create(:project) }

    before do
      types = [
        FactoryGirl.create(:type, name: 'SampleType', is_milestone: true, color_id: color.id),
        FactoryGirl.create(:type, color_id: color.id),
        FactoryGirl.create(:type, color_id: color.id)
      ]
      project.types = types
      project.save

      assign(:project, project)
      render
    end

    subject { response.body }

    it 'contains 3 planning_element_types' do
      is_expected.to have_json_size(3).at_path('project/types')
    end

    it 'renders the current name, color, is_milestone for a planning_element_type' do
      expected_json = { name: 'SampleType', is_milestone: true, color: { hexcode: '#FF0000', name: 'red' } }.to_json

      is_expected.to be_json_eql(expected_json).at_path('project/types/0')
    end

  end

  describe 'with a project having project_associations' do
    let(:project) { FactoryGirl.create(:public_project) }

    before do
      FactoryGirl.create(:project_association,
                         project_a_id: project.id,
                         project_b_id: FactoryGirl.create(:project, name: 'Associated Project #1', identifier: 'assoc_1', is_public: true).id)
      FactoryGirl.create(:project_association,
                         project_b_id: project.id,
                         project_a_id: FactoryGirl.create(:project, name: 'Associated Project #2', identifier: 'assoc_2', is_public: true).id)

      # Adding invisible association to make sure, that it is not included in the output
      FactoryGirl.create(:project_association,
                         project_a_id: project.id,
                         project_b_id: FactoryGirl.create(:project, is_public: false).id)
    end

    before do
      assign(:project, project)
      render
    end

    subject { response.body }

    it 'render 2 project_associations' do
      is_expected.to have_json_size(2).at_path('project/project_associations')
    end

    it 'render a project_association with the from- and -to-project' do
      expected_json = { project: { name: 'Associated Project #1', identifier: 'assoc_1' } }.to_json

      is_expected.to be_json_eql(expected_json).at_path('project/project_associations/0')
    end

  end

  describe 'with a project having custom field values' do
    let(:project) { FactoryGirl.create(:project) }
    let(:custom_field) do
      FactoryGirl.create :issue_custom_field,
                         name: 'Belag',
                         field_format: 'text',
                         projects: [project],
                         types: [(Type.find_by_name('None') || FactoryGirl.create(:type_standard))]
    end

    before do
      custom_value = CustomValue.new(
        custom_field: custom_field,
        value: 'Wurst')
      project.custom_values << custom_value

      assign(:project, project)
      render
    end

    subject { response.body }

    it 'renders custom field values' do
      is_expected.to have_json_path('project/custom_fields')

      expected_json = { name: custom_field.name, value: 'Wurst' }.to_json
      is_expected.to be_json_eql(expected_json).at_path('project/custom_fields/0')
    end
  end

end
