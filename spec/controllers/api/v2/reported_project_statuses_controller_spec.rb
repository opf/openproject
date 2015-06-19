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

require File.expand_path('../../../../spec_helper', __FILE__)

describe Api::V2::ReportedProjectStatusesController, type: :controller do

  let(:valid_user) { FactoryGirl.create(:user) }
  let(:available_reported_project_status) do
    FactoryGirl.create(:reported_project_status,
                       id: '1337')
  end

  before do
    allow(User).to receive(:current).and_return valid_user
  end

  describe 'with project_type scope' do
    let(:project_type) { FactoryGirl.create(:project_type) }

    describe 'index.xml' do
      describe 'with unknown project_type' do
        it 'raises ActiveRecord::RecordNotFound errors' do
          expect {
            get 'index', project_type_id: '0', format: 'xml'
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      describe 'with valid project_type' do
        describe 'with no reported_project_statuses available' do
          it 'assigns an empty reported_project_statuses array' do
            get 'index', project_type_id: project_type.id, format: 'xml'
            expect(assigns(:reported_project_statuses)).to eq([])
          end

          it 'renders the index builder template' do
            get 'index', project_type_id: project_type.id, format: 'xml'
            expect(response).to render_template('api/v2/reported_project_statuses/index', formats: ['api'])
          end
        end

        describe 'with some reported_project_statuses available' do
          before do
            @created_reported_project_statuses = [
              FactoryGirl.create(:reported_project_status),
              FactoryGirl.create(:reported_project_status),
              FactoryGirl.create(:reported_project_status)
            ]
            # Creating one ReportedProjectStatus that is inactive and should not
            # show up the assigned values below
            FactoryGirl.create(:reported_project_status, active: false)

            # Assign all existing ReportedProjectStatus to a ProjectStatus via the
            # AvailableProjectStatus model
            ReportedProjectStatus.all.each do |reported_status|
              FactoryGirl.create(:available_project_status,
                                 project_type_id: project_type.id,
                                 reported_project_status_id: reported_status.id)
            end

            # Creating an additional ReportedProjectStatus, that should not show
            # up in the lists below
            FactoryGirl.create(:reported_project_status)
          end

          it 'assigns an array with all reported_project_statuses' do
            get 'index', project_type_id: project_type.id, format: 'xml'
            expect(assigns(:reported_project_statuses)).to eq(@created_reported_project_statuses)
          end

          it 'renders the index template' do
            get 'index', project_type_id: project_type.id, format: 'xml'
            expect(response).to render_template('api/v2/reported_project_statuses/index', formats: ['api'])
          end
        end
      end
    end

    describe 'show.xml' do
      describe 'with unknown project_type' do

        it 'raises ActiveRecord::RecordNotFound errors' do
          expect {
            get 'show', project_type_id: '0', id: '1337', format: 'xml'
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      describe 'with unknown reported_project_status' do
        it 'raises ActiveRecord::RecordNotFound errors' do
          expect {
            get 'show', project_type_id: project_type.id, id: '1337', format: 'xml'
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      describe 'with inactive reported_project_status' do
        let :available_reported_project_status do
          FactoryGirl.create(:reported_project_status,
                             id: '1337',
                             active: false)
        end
        before do
          FactoryGirl.create(:available_project_status,
                             project_type_id: project_type.id,
                             reported_project_status_id: available_reported_project_status.id)
        end

        it 'raises ActiveRecord::RecordNotFound errors' do
          expect {
            get 'show', project_type_id: project_type.id, id: '1337', format: 'xml'
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      describe 'with reported_project_status not available for project_type' do
        it 'raises ActiveRecord::RecordNotFound errors' do
          available_reported_project_status
          expect {
            get 'show', project_type_id: project_type.id, id: '1337', format: 'xml'
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      describe 'with an available reported_project_status' do
        before do
          FactoryGirl.create(:available_project_status,
                             project_type_id: project_type.id,
                             reported_project_status_id: available_reported_project_status.id)
        end

        it 'assigns the available reported_project_status' do
          get 'show', project_type_id: project_type.id, id: '1337', format: 'xml'
          expect(assigns(:reported_project_status)).to eq(available_reported_project_status)
        end

        it 'renders the show template' do
          get 'show', project_type_id: project_type.id, id: '1337', format: 'xml'
          expect(response).to render_template('api/v2/reported_project_statuses/show', formats: ['api'])
        end
      end
    end
  end

  describe 'without project_type scope' do
    describe 'index.xml' do
      describe 'with no reported_project_statuses available' do
        it 'assigns an empty reported_project_statuses array' do
          get 'index', format: 'xml'
          expect(assigns(:reported_project_statuses)).to eq([])
        end

        it 'renders the index builder template' do
          get 'index', format: 'xml'
          expect(response).to render_template('api/v2/reported_project_statuses/index', formats: ['api'])
        end
      end

      describe 'with some reported_project_statuses available' do
        before do
          @created_reported_project_statuses = [
            FactoryGirl.create(:reported_project_status),
            FactoryGirl.create(:reported_project_status),
            FactoryGirl.create(:reported_project_status)
          ]
          FactoryGirl.create(:reported_project_status, active: false)
        end

        it 'assigns an array with all reported_project_statuses' do
          get 'index', format: 'xml'
          expect(assigns(:reported_project_statuses)).to eq(@created_reported_project_statuses)
        end

        it 'renders the index template' do
          get 'index', format: 'xml'
          expect(response).to render_template('api/v2/reported_project_statuses/index', formats: ['api'])
        end
      end
    end

    describe 'show.xml' do
      describe 'with unknown reported_project_status' do
        it 'raises ActiveRecord::RecordNotFound errors' do
          expect {
            get 'show', id: '1337', format: 'xml'
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      describe 'with inactive reported_project_status' do
        before do
          @available_reported_project_status = FactoryGirl.create(:reported_project_status,
                                                                  id: '1337',
                                                                  active: false)
        end

        it 'raises ActiveRecord::RecordNotFound errors' do
          expect {
            get 'show', id: '1337', format: 'xml'
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      describe 'with an available reported_project_status' do
        before do
          @available_reported_project_status = FactoryGirl.create(:reported_project_status,
                                                                  id: '1337')
        end

        it 'assigns the available reported_project_status' do
          get 'show', id: '1337', format: 'xml'
          expect(assigns(:reported_project_status)).to eq(@available_reported_project_status)
        end

        it 'renders the show template' do
          get 'show', id: '1337', format: 'xml'
          expect(response).to render_template('api/v2/reported_project_statuses/show', formats: ['api'])
        end
      end
    end
  end
end
