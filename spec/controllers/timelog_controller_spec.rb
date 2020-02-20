#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe TimelogController, type: :controller do
  let!(:activity) { FactoryBot.create(:default_activity) }
  let(:project) { FactoryBot.create(:project) }
  let(:user) do
    FactoryBot.create(:admin,
                      member_in_project: project)
  end
  let(:params) do
    { 'time_entry' => { 'work_package_id' => work_package_id,
                        'spent_on' => Date.today.strftime('%Y-%m-%d'),
                        'hours' => '5',
                        'comments' => '',
                        'custom_field_values' => { custom_field.id.to_s => 'wurst' },
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
      it { expect(response).to redirect_to(project_time_entries_path(project)) }
    end

    let(:custom_field) do
      FactoryBot.build_stubbed :time_entry_custom_field,
                               name: 'supplies',
                               is_required: true
    end

    let!(:service) do
      service = double('create_service')

      allow(TimeEntries::CreateService)
        .to receive(:new)
        .with(user: user)
        .and_return(service)

      allow(service)
        .to receive(:call)
        .with(params['time_entry'].merge(project: project))
        .and_return(service_result)

      service
    end

    let(:time_entry) { double("created time entry", project: project) }

    let(:service_result) do
      ServiceResult.new(success: true, errors: [], result: time_entry)
    end

    describe '#valid' do
      before do
        expect(service)
          .to receive(:call)
          .with(params['time_entry'].merge(project: project))
          .and_return(service_result)

        post :create, params: params
      end

      it_behaves_like 'successful timelog creation'
    end

    describe '#with failures on creation' do
      let(:service_result) do
        ServiceResult.new(success: false, errors: [], result: time_entry)
      end

      before do
        post :create, params: params
      end

      it { expect(response).to render_template(:edit) }
    end

    context 'with invalid project' do
      describe '#invalid' do
        let(:project_id) { -1 }

        before do
          post :create, params: params
        end

        it { expect(response.status).to eq(404) }
      end
    end
  end

  describe '#destroy' do
    let(:time_entry) do
      FactoryBot.build_stubbed(:time_entry).tap do |entry|
        allow(TimeEntry)
          .to receive(:find)
          .with(entry.id.to_s)
          .and_return(entry)
      end
    end

    let(:expected_destroy_response) { true }

    before do
      expect(time_entry)
        .to receive(:destroy)
        .and_return(expected_destroy_response)

      allow(time_entry)
        .to receive(:destroyed?)
        .and_return(expected_destroy_response)

      delete :destroy, params: { id: time_entry.id }
    end

    context 'successful' do
      it 'redirects to index' do
        expect(response)
          .to redirect_to project_time_entries_path(time_entry.project)
      end

      it 'returns with a success flash' do
        expect(flash[:notice])
          .to eql I18n.t(:notice_successful_delete)
      end
    end

    context 'failure' do
      let(:expected_destroy_response) { false }

      it 'redirects to index' do
        expect(response)
          .to redirect_to project_time_entries_path(time_entry.project)
      end

      it 'returns with a success flash' do
        expect(flash[:error])
          .to eql I18n.t(:notice_unable_delete_time_entry)
      end
    end
  end
end
