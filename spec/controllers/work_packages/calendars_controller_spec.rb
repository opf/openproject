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

describe WorkPackages::CalendarsController, type: :controller do
  let(:project) { FactoryGirl.create(:project) }
  let(:role) {
    FactoryGirl.create(:role,
                       permissions: [:view_calendar])
  }
  let(:user) {
    FactoryGirl.create(:user,
                       member_in_project: project,
                       member_through_role: role)
  }
  let(:work_package) {
    FactoryGirl.create(:work_package,
                       project: project)
  }

  before do login_as(user) end

  describe '#index' do
    shared_examples_for 'calendar#index' do
      subject { response }

      it { is_expected.to be_success }

      it { is_expected.to render_template('work_packages/calendars/index') }

      context 'assigns' do
        subject { assigns(:calendar) }

        it { is_expected.to be_truthy }
      end
    end

    context 'cross-project' do
      before do
        get :index
      end

      it_behaves_like 'calendar#index'
    end

    context 'project' do
      before do
        work_package

        get :index, params: { project_id: project.id }
      end

      it_behaves_like 'calendar#index'
    end

    context 'custom query' do
      let (:query) {
        FactoryGirl.create(:query,
                           project: nil,
                           user: user)
      }

      before do
        get :index, params: { query_id: query.id }
      end

      it_behaves_like 'calendar#index'
    end

    describe 'start of week' do
      context 'Sunday' do
        before do
          allow(Setting).to receive(:start_of_week).and_return(7)

          get :index, params: { month: '1', year: '2010' }
        end

        it_behaves_like 'calendar#index'

        describe '#view' do
          render_views

          subject { response }

          it { assert_select('tr td.week-number', content: '53') }

          it { assert_select('tr td.odd', content: '27') }

          it { assert_select('tr td.even', content: '2') }

          it { assert_select('tr td.week-number', content: '1') }

          it { assert_select('tr td.odd', content: '3') }

          it { assert_select('tr td.even', content: '9') }
        end
      end

      context 'Monday' do
        before do
          allow(Setting).to receive(:start_of_week).and_return(1)

          get :index, params: { month: '1', year: '2010' }
        end

        it_behaves_like 'calendar#index'

        describe '#view' do
          render_views

          subject { response }

          it { assert_select('tr td.week-number', content: '53') }

          it { assert_select('tr td.even', content: '28') }

          it { assert_select('tr td.even', content: '3') }

          it { assert_select('tr td.week-number', content: '1') }

          it { assert_select('tr td.even', content: '4') }

          it { assert_select('tr td.even', content: '10') }
        end
      end
    end
  end
end
