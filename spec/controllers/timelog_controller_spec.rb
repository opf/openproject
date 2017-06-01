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

describe TimelogController, type: :controller do
  let!(:activity) { FactoryGirl.create(:default_activity) }
  let(:project) { FactoryGirl.create(:project) }
  let(:user) do
    FactoryGirl.create(:admin,
                       member_in_project: project)
  end
  let(:params) do
    { 'time_entry' => { 'work_package_id' => work_package_id,
                        'spent_on' => Date.today.strftime('%Y-%m-%d'),
                        'hours' => '5',
                        'comments' => '',
                        'activity_id' => activity.id.to_s },
      'project_id' => project_id.to_s }
  end
  let(:project_id) { project.id }
  let(:work_package_id) { '' }

  before do
    login_as(user)
  end

  describe '#create' do
    shared_examples_for 'successful timelog creation' do
      it { expect(response).to be_a_redirect }

      it { expect(response).to redirect_to(project_time_entries_path(project)) }
    end

    context 'project' do
      describe '#valid' do
        before do
          post :create, params: params
        end

        it_behaves_like 'successful timelog creation'
      end

      describe '#invalid' do
        let(:project_id) { -1 }

        before do
          post :create, params: params
        end

        it { expect(response.status).to eq(404) }
      end

      context 'with a required custom field' do
        let(:custom_field) do
          FactoryGirl.build_stubbed :time_entry_custom_field,
                                    name: 'supplies',
                                    is_required: true
        end

        let(:time_entry) { double('time_entry', save: true, project: project) }

        before do
          allow(TimeEntry)
            .to receive(:new)
            .and_return(time_entry)
        end

        describe 'which is given' do
          before do
            params['time_entry']['custom_field_values'] = { custom_field.id.to_s => 'wurst' }

            expect(time_entry)
              .to receive(:attributes=)
              .with(params['time_entry'])

            post :create, params: params
          end

          it_behaves_like 'successful timelog creation'
        end
      end
    end

    context 'work_package' do
      describe '#valid' do
        let(:work_package) do
          FactoryGirl.create(:work_package,
                             project: project)
        end
        let(:work_package_id) { work_package.id }

        before do
          post :create, params: params
        end

        it_behaves_like 'successful timelog creation'
      end

      describe '#invalid' do
        let(:work_package_id) { 'blub' }

        before do
          post :create, params: params
        end

        it { expect(response).to render_template(:edit) }

        describe '#view' do
          render_views

          it { expect(response.body).to match(/Work package is invalid/) }
        end
      end
    end
  end
end
