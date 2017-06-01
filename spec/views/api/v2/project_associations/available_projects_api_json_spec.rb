#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

require 'spec_helper'

describe 'api/v2/project_associations/available_projects.api.rabl', type: :view do
  before do
    params[:format] = 'json'
  end

  describe 'with an assigned project_association' do
    let(:project_a) {
      FactoryGirl.create(:project, id: 1234,
                                   identifier: 'test_project_a',
                                   name: 'Test Project A',
                                   created_on: Time.parse('Thu Jan 06 12:35:00 +0100 2011'),
                                   updated_on: Time.parse('Fri Jan 07 12:35:00 +0100 2011'))
    }

    let(:project_b) {
      FactoryGirl.create(:project, id: 2345,
                                   identifier: 'test_project_b',
                                   name: 'Test Project B',
                                   created_on: Time.parse('Thu Jan 06 12:35:00 +0100 2011'),
                                   updated_on: Time.parse('Fri Jan 07 12:35:00 +0100 2011'))
    }

    let(:available_projects) { [{ project: project_a, level: 1 }] }
    let(:disabled_projects)  { [{ project: project_b, level: 1 }] }

    before do
      assign(:elements, available_projects)
      assign(:disabled, disabled_projects)
      render
    end

    subject { rendered }

    it 'renders a list of projects available for association' do
      expected_json = { name: 'Test Project A',
                        identifier: 'test_project_a',
                        level: 1,
                        disabled: false,
                        created_on: '2011-01-06T11:35:00Z',
                        updated_on: '2011-01-07T11:35:00Z'
                       }.to_json
      is_expected.to be_json_eql(expected_json).at_path('projects/0')
    end
  end
end
