#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "#{File.dirname(__FILE__)}/../spec_helper"

RSpec.describe MeetingsController do
  let(:user) { create(:admin) }
  let(:project) { create(:project) }
  let(:other_project) { create(:project) }

  before do
    allow(User).to receive(:current).and_return user

    allow(Project).to receive(:find).and_return(project)

    allow(controller).to receive(:authorize)
    allow(controller).to receive(:authorize_global)
    allow(controller).to receive(:check_if_login_required)
  end

  describe 'GET' do
    describe 'index' do
      let(:meetings) do
        [
          create(:meeting, project:),
          create(:meeting, project:),
          create(:meeting, project: other_project)
        ]
      end

      describe 'html' do
        context 'when requesting meetings globally' do
          before do
            get 'index'
          end

          it { expect(response).to be_successful }
          it { expect(assigns(:meetings)).to match_array meetings }
        end

        context 'when requesting meetings scoped to a project ID' do
          before do
            get 'index', params: { project_id: project.id }
          end

          it { expect(response).to be_successful }
          it { expect(assigns(:meetings)).to match_array meetings[0..1] }
        end
      end
    end

    describe 'show' do
      let(:meeting) { create(:meeting, project:, agenda: nil) }

      describe 'html' do
        before do
          get 'show', params: { id: meeting.id }
        end

        it { expect(response).to be_successful }
        it { expect(assigns(:meeting)).to eql meeting }
      end
    end

    describe 'new' do
      let(:meeting) { Meeting.new(project:) }

      before do
        allow(Project).to receive(:find).and_return(project)
        allow(Meeting).to receive(:new).and_return(meeting)
      end

      describe 'html' do
        before do
          get 'new',  params: { project_id: project.id }
        end

        it { expect(response).to be_successful }
        it { expect(assigns(:meeting)).to eql meeting }
      end
    end

    describe 'edit' do
      let(:meeting) { create(:meeting, project:) }

      describe 'html' do
        before do
          get 'edit', params: { id: meeting.id }
        end

        it { expect(response).to be_successful }
        it { expect(assigns(:meeting)).to eql meeting }
      end
    end

    describe 'create' do
      render_views

      before do
        allow(Project).to receive(:find).and_return(project)
        post :create,
             params: {
               project_id: project.id,
               meeting: {
                 title: 'Foobar',
                 duration: '1.0'
               }.merge(params)
             }
      end

      describe 'invalid start_date' do
        let(:params) do
          {
            start_date: '-',
            start_time_hour: '10:00'
          }
        end

        it 'renders an error' do
          expect(response).to have_http_status :ok
          expect(response).to render_template :new
          expect(response.body)
            .to have_selector '#errorExplanation li',
                              text: "Start date #{I18n.t('activerecord.errors.messages.not_an_iso_date')}"
        end
      end

      describe 'invalid start_time_hour' do
        let(:params) do
          {
            start_date: '2015-06-01',
            start_time_hour: '-'
          }
        end

        it 'renders an error' do
          expect(response).to have_http_status :ok
          expect(response).to render_template :new
          expect(response.body)
            .to have_selector '#errorExplanation li',
                              text: "Starting time #{I18n.t('activerecord.errors.messages.invalid_time_format')}"
        end
      end
    end
  end
end
