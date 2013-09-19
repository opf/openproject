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

describe 'api/v2/reportings/_reporting.api' do
  before do
    view.extend TimelinesHelper
  end

  # added to pass in locals
  def render
    params[:format] = 'xml'
    super(:partial => 'api/v2/reportings/reporting.api', :object => reporting)
  end

  describe 'with an assigned reporting' do
    let(:project_a) { FactoryGirl.create(:project, :id => 1234,
                                               :identifier => 'test_project_a',
                                               :name => 'Test Project A') }
    let(:project_b) { FactoryGirl.create(:project, :id => 1235,
                                               :identifier => 'test_project_b',
                                               :name => 'Test Project B') }

    let(:reporting) { FactoryGirl.build(:reporting,
                                    :id => 1,
                                    :project_id => project_a.id,
                                    :reporting_to_project_id => project_b.id,

                                    :created_at => Time.parse('Thu Jan 06 12:35:00 +0100 2011'),
                                    :updated_at => Time.parse('Fri Jan 07 12:35:00 +0100 2011')) }

    it 'renders a reporting node' do
      render
      response.should have_selector('reporting', :count => 1)
    end

    describe 'reporting node' do
      it 'contains an id element containing the reporting id' do
        render
        response.should have_selector('reporting id', :text => '1')
      end

      it 'contains a project node' do
        render
        response.should have_selector('reporting project[id="1234"][name="Test Project A"][identifier=test_project_a]', :count => 1)
      end

      it 'contains a reporting_to_project node' do
        render
        response.should have_selector('reporting reporting_to_project[id="1235"][name="Test Project B"][identifier=test_project_b]', :count => 1)
      end

      it 'does not contain a reported_project_status element' do
        render
        response.should_not have_selector('reporting reported_project_status')
      end

      it 'does not contain a reported_project_status_comment element' do
        render
        response.should_not have_selector('reporting reported_project_status_comment')
      end

      it 'contains a created_on element containing the reporting created_on in UTC in ISO 8601' do
        render
        response.should have_selector('reporting created_at', :text => '2011-01-06T11:35:00Z')
      end

      it 'contains an updated_on element containing the reporting updated_on in UTC in ISO 8601' do
        render
        response.should have_selector('reporting updated_at', :text => '2011-01-07T11:35:00Z')
      end
    end

    describe 'reporting node with reported_project_status' do
      let(:reported_project_status) { FactoryGirl.create(:reported_project_status,
                                                     :id => 1,
                                                     :name => 'beste') }
      let(:reporting) { FactoryGirl.build(:reporting,
                                      :reported_project_status_id => reported_project_status.id) }

      it 'contains a reported_project_status element containing the reporting id and name of the status' do
        render
        response.should have_selector('reporting reported_project_status[id="1"][name=beste]')
      end
    end

    describe 'reporting node with reported_project_status_comment' do
      let(:reporting) { FactoryGirl.build(:reporting,
                                      :reported_project_status_comment => 'alea iacta est') }

      it 'contains a reported_project_status_comment element containing the reporting id and name of the status' do
        render
        response.should have_selector('reporting reported_project_status_comment', :text => 'alea iacta est')
      end
    end
  end
end
