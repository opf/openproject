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

describe 'api/v2/planning_elements/index.api.rabl', type: :view do
  before do
    params[:format] = 'json'
  end

  describe 'with no planning elements available' do
    before do
      assign(:planning_elements, [])
      render
    end

    it 'renders an empty planning_elements document' do
      expect(response.body).to have_json_path('planning_elements')
      expect(response.body).to have_json_size(0).at_path('planning_elements')
    end
  end

  describe 'with 3 planning elements available' do

    let(:project) { FactoryGirl.build(:project_with_types, name: 'Sample Project', identifier: 'sample_project') }
    let(:wp1) { FactoryGirl.build(:work_package, subject: 'Subject #1', project: project) }
    let(:wp2) { FactoryGirl.build(:work_package, subject: 'Subject #2', project: project) }
    let(:wp3) { FactoryGirl.build(:work_package, subject: 'Subject #3', project: project) }

    let(:planning_elements) { [wp1, wp2, wp3] }

    before do
      assign(:planning_elements, planning_elements)
      render
    end

    subject do
      response.body
    end

    it 'should render 3 planning-elements' do
      is_expected.to have_json_size(3).at_path('planning_elements')
    end

    it 'should render the subject' do
      expect(response.body).to be_json_eql('Subject #1'.to_json).at_path('planning_elements/0/subject')
    end

    it 'should render a the type_id' do
      type = project.types.first
      expected_json = { name: type.name }.to_json

      is_expected.to be_json_eql(type.id.to_json).at_path('planning_elements/0/type_id')

    end

    it 'should render a status-id' do
      expect(response.body).to be_json_eql(wp1.status.id.to_json).at_path('planning_elements/0/status_id')
    end

    it 'should render a project-id' do
      is_expected.to be_json_eql(project.id.to_json).at_path(('planning_elements/0/project_id'))
    end

  end

  describe 'with 1 custom field planning element' do
    let (:custom_field) {
      FactoryGirl.create(:work_package_custom_field,
                         name: 'Database',
                         field_format: 'list',
                         possible_values: ['MySQL', 'PostgreSQL', 'Oracle'],
                         is_for_all: true)
    }

    let(:project) { FactoryGirl.build(:project_with_types, name: 'Sample Project', identifier: 'sample_project') }
    let(:wp1) { FactoryGirl.build(:work_package, subject: 'Subject #1', project: project) }
    let(:wp2) { FactoryGirl.build(:work_package, subject: 'Subject #2', project: project) }

    let(:planning_elements) { [wp1, wp2] }

    before do
      project.types[0].custom_fields << custom_field
      project.save!

      wp1.save!
      wp1.custom_values[0].value = 'MySQL'
      wp1.save!

      assign(:planning_elements, planning_elements)
      render
    end

    subject do
      response.body
    end

    it 'should render custom field values' do
      expect(response.body).to be_json_eql('MySQL'.to_json).at_path("planning_elements/0/cf_#{custom_field.id}")
      expect(response.body).to have_json_path('planning_elements/1')
      expect(response.body).not_to have_json_path("planning_elements/1/cf_#{custom_field.id}")
    end
  end
end
