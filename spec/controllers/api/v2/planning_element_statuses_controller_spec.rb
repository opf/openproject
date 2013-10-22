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

require File.expand_path('../../../../spec_helper', __FILE__)

describe Api::V2::PlanningElementStatusesController do
  let(:current_user) { FactoryGirl.create(:admin) }

  before do
    User.stub(:current).and_return current_user
  end

  describe 'index.xml' do
    def fetch
      get 'index', :format => 'xml'
    end
    it_should_behave_like "a controller action with unrestricted access"

    describe 'with no planning element statuses available' do
      it 'assigns an empty planning_element_statuses array' do
        get 'index', :format => 'xml'
        assigns(:statuses).should == []
      end

      it 'renders the index builder template' do
        get 'index', :format => 'xml'
        response.should render_template('planning_element_statuses/index', :formats => ["api"])
      end
    end

    describe 'with 3 planning element statuses available' do
      before do
        @created_planning_element_statuses = [
          FactoryGirl.create(:planning_element_status),
          FactoryGirl.create(:planning_element_status),
          FactoryGirl.create(:planning_element_status)
        ]
      end

      it 'assigns an array with all planning element statuses' do
        get 'index', :format => 'xml'
        assigns(:statuses).should == @created_planning_element_statuses
      end

      it 'renders the index template' do
        get 'index', :format => 'xml'
        response.should render_template('planning_element_statuses/index', :formats => ["api"])
      end
    end
  end

  describe 'show.xml' do
    describe 'with unknown planning element status' do
      if false # would like to write it this way
        it 'returns status code 404' do
          get 'show', :id => '1337', :format => 'xml'

          response.status.should == '404 Not Found'
        end

        it 'returns an empty body' do
          get 'show', :id => '1337', :format => 'xml'

          response.body.should be_empty
        end

      else # but have to write it that way
        it 'raises ActiveRecord::RecordNotFound errors' do
          lambda do
            get 'show', :id => '1337', :format => 'xml'
          end.should raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    describe 'with an available planning element status' do
      before do
        @available_planning_element_status = FactoryGirl.create(:planning_element_status, :id => '1337')
      end

      def fetch
        get 'show', :id => '1337', :format => 'xml'
      end
      it_should_behave_like "a controller action with unrestricted access"

      it 'assigns the available planning element status' do
        get 'show', :id => '1337', :format => 'xml'
        assigns(:planning_element_status).should == @available_planning_element_status
      end

      it 'renders the show template' do
        get 'show', :id => '1337', :format => 'xml'
        response.should render_template('planning_element_statuses/show', :formats => ["api"])
      end
    end
  end
end
