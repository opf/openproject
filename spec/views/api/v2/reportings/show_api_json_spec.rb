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

describe 'api/v2/reportings/show.api.rabl', type: :view do

  before do
    params[:format] = 'json'
  end

  describe 'with an assigned reporting' do
    let(:project_a) {
      FactoryGirl.create(:project, id: 1234,
                                   identifier: 'test_project_a',
                                   name: 'Test Project A')
    }
    let(:project_b) {
      FactoryGirl.create(:project, id: 1235,
                                   identifier: 'test_project_b',
                                   name: 'Test Project B')
    }

    let(:reporting) {
      FactoryGirl.build(:reporting,
                        id: 1,
                        project_id: project_a.id,
                        reporting_to_project_id: project_b.id,
                        reported_project_status_comment: 'Sample Comment',

                        created_at: Time.parse('Thu Jan 06 12:35:00 +0100 2011'),
                        updated_at: Time.parse('Fri Jan 07 12:35:00 +0100 2011'))
    }

    before do
      assign(:reporting, reporting)
      render
    end

    subject { response.body }

    it 'renders a reporting document' do
      expect(response).to have_json_path('reporting')
    end

    it 'renders the details of a reporting' do
      expected_json = { project: { identifier: 'test_project_a',
                                   name: 'Test Project A' },
                        reporting_to_project: { identifier: 'test_project_b',
                                                name: 'Test Project B' },
                        reported_project_status_comment: 'Sample Comment'
                      }.to_json

      is_expected.to be_json_eql(expected_json).at_path('reporting')
    end

  end

  describe 'reporting node with reported_project_status' do
    let(:reported_project_status) {
      FactoryGirl.create(:reported_project_status,
                         id: 1,
                         name: 'beste')
    }
    let(:reporting) {
      FactoryGirl.build(:reporting,
                        reported_project_status_id: reported_project_status.id)
    }

    before do
      assign(:reporting, reporting)
      render
    end

    subject { response.body }

    it 'renders the reported project-status' do
      expected_json = { name: 'beste' }.to_json

      is_expected.to be_json_eql(expected_json).at_path('reporting/reported_project_status')
    end

  end

end
