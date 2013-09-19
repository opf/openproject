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

describe 'api/v2/project_associations/_project_association.api' do
  before do
    view.extend TimelinesHelper
  end

  # added to pass in locals
  def render
    params[:format] = 'xml'
    super(:partial => 'api/v2/project_associations/project_association.api', :object => project_association)
  end

  describe 'with an assigned project_association' do
    let(:project_a) { FactoryGirl.create(:project, :id => 1234,
                                               :identifier => 'test_project_a',
                                               :name => 'Test Project A') }
    let(:project_b) { FactoryGirl.create(:project, :id => 1235,
                                               :identifier => 'test_project_b',
                                               :name => 'Test Project B') }

    let(:project_association) { FactoryGirl.build(:project_association,
                                              :id => 1,
                                              :project_a_id => project_a.id,
                                              :project_b_id => project_b.id,
                                              :description => 'Description of this project_association',

                                              :created_at => Time.parse('Thu Jan 06 12:35:00 +0100 2011'),
                                              :updated_at => Time.parse('Fri Jan 07 12:35:00 +0100 2011')) }

    it 'renders a project_association node' do
      render
      response.should have_selector('project_association', :count => 1)
    end

    describe 'project_association node' do
      it 'contains an id element containing the project_association id' do
        render
        response.should have_selector('project_association id', :text => '1')
      end

      it 'contains a projects array' do
        render
        response.should have_selector('project_association projects[size="2"][type=array]', :count =>  1)
      end

      describe 'projects node' do
        it 'contains two project nodes - one for each project taking part in the association' do
          render
          response.should have_selector('project_association projects project', :count => 2)
        end

        it 'contains one project node for project_a' do
          render
          response.should have_selector('project_association projects project[id="1234"][identifier=test_project_a][name="Test Project A"]')
        end

        it 'contains one project node for project_b' do
          render
          response.should have_selector('project_association projects project[id="1235"][identifier=test_project_b][name="Test Project B"]')
        end
      end

      it 'contains a description element' do
        render
        response.should have_selector('project_association description', :text => 'Description of this project_association')
      end

      it 'contains a created_at element containing the project_association created_at in UTC in ISO 8601' do
        render
        response.should have_selector('project_association created_at', :text => '2011-01-06T11:35:00Z')
      end

      it 'contains an updated_at element containing the project_association updated_at in UTC in ISO 8601' do
        render
        response.should have_selector('project_association updated_at', :text => '2011-01-07T11:35:00Z')
      end
    end
  end
end
