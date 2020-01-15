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

describe ForumsController, type: :controller do
  shared_let(:user) { FactoryBot.create(:user) }
  let(:project) { FactoryBot.create(:project) }
  let!(:forum) { FactoryBot.create(:forum, project: project) }

  before do
    disable_flash_sweep
  end

  describe '#index' do

    context 'public project' do
      let(:project) { FactoryBot.create(:public_project) }
      let!(:role) { FactoryBot.create(:non_member) }

      it 'renders the index template' do
        as_logged_in_user(user) do
          get :index, params: { project_id: project.id }
        end

        expect(response).to be_successful
        expect(response).to render_template 'forums/index'
        expect(assigns(:forums)).to be_present
        expect(assigns(:project)).to be_present
      end
    end

    context 'assuming authorized' do
      it 'renders the index template' do
        as_logged_in_user(user) do
          allow(@controller).to receive(:authorize).and_return(true)
          get :index, params: { project_id: project.id }
        end
        expect(response).to be_successful
      end
    end

    it 'renders 404 for not found' do
      get :index, params: { project_id: 'not found' }
      expect(response.status).to eq 404
    end
  end

  describe '#show' do
    before do
      expect(project).to receive_message_chain(:forums, :find).and_return(forum)
      expect(@controller).to receive(:authorize)
      expect(@controller).to receive(:find_project_by_project_id) do
        @controller.instance_variable_set(:@project, project)
      end
    end

    it 'renders the show template' do
      get :show, params: { project_id: project.id, id: 1 }
      expect(response).to be_successful
      expect(response).to render_template 'forums/show'
    end
  end

  describe '#create' do
    let(:params) { { project_id: project.id, forum: forum_params } }
    let(:forum_params) { { name: 'my forum', description: 'awesome forum' } }

    before do
      expect(@controller).to receive(:authorize)
      expect(@controller).to receive(:find_project_by_project_id) do
        @controller.instance_variable_set(:@project, project)
      end

      # parameter expectation needs to have strings as keys
      expect(Forum)
        .to receive(:new)
        .with(ActionController::Parameters.new(forum_params).permit!)
        .and_return(forum)
    end

    describe 'w/ the params beeing valid' do
      before do
        expect(forum).to receive(:save).and_return(true)

        as_logged_in_user user do
          post :create, params: params
        end
      end

      it 'should redirect to the index page if successful' do
        expect(response)
          .to redirect_to controller: '/forums',
                          action: 'index',
                          project_id: project.id
      end

      it 'have a successful creation flash' do
        expect(flash[:notice]).to eq(I18n.t(:notice_successful_create))
      end
    end

    describe 'w/ the params beeing invalid' do
      before do
        expect(forum).to receive(:save).and_return(false)

        as_logged_in_user user do
          post :create, params: params
        end
      end

      it 'should render the new template' do
        expect(response).to render_template('new')
      end
    end
  end

  describe '#destroy' do
    let(:forum_params) { { name: 'my forum', description: 'awesome forum' } }

    before do
      expect(@controller).to receive(:authorize)
      expect(project).to receive_message_chain(:forums, :find).and_return(forum)
      expect(@controller).to receive(:find_project_by_project_id) do
        @controller.instance_variable_set(:@project, project)
      end
    end

    it 'will request destruction and redirect' do
      expect(forum).to receive(:destroy)
      delete :destroy, params: { project_id: project.id, id: 1 }
      expect(response).to be_redirect
    end
  end

  describe '#move' do
    let(:project) { FactoryBot.create(:project) }
    let!(:forum_1) {
      FactoryBot.create(:forum,
                         project: project,
                         position: 1)
    }
    let!(:forum_2) {
      FactoryBot.create(:forum,
                         project: project,
                         position: 2)
    }

    before do
      allow(@controller).to receive(:authorize).and_return(true)
    end

    describe '#higher' do
      let(:move_to) { 'higher' }

      before do
        post 'move', params: { id: forum_2.id,
                               project_id: forum_2.project_id,
                               forum: { move_to: move_to } }
      end

      it do expect(forum_2.reload.position).to eq(1) end

      it do expect(response).to be_redirect end

      it do
        expect(response)
          .to redirect_to controller: '/forums',
                          action: 'index',
                          project_id: project.id
      end
    end
  end

  describe '#update' do
    let!(:forum) {
      FactoryBot.create(:forum, name: 'Forum name',
                                 description: 'Forum description')
    }

    before do
      expect(@controller).to receive(:authorize)
    end

    describe 'w/ the params beeing valid' do
      before do
        as_logged_in_user user do
          put :update, params: { id: forum.id,
                                 project_id: forum.project_id,
                                 forum: { name: 'New name', description: 'New description' } }
        end
      end

      it 'should redirect to the index page if successful' do
        expect(response).to redirect_to controller: '/forums',
                                        action: 'index',
                                        project_id: forum.project_id
      end

      it 'have a successful update flash' do
        expect(flash[:notice]).to eq(I18n.t(:notice_successful_update))
      end

      it 'should change the database entry' do
        forum.reload
        expect(forum.name).to eq('New name')
        expect(forum.description).to eq('New description')
      end
    end

    describe 'w/ the params beeing invalid' do
      before do
        as_logged_in_user user do
          post :update, params: { id: forum.id,
                                  project_id: forum.project_id,
                                  forum: { name: '', description: 'New description' } }
        end
      end

      it 'should render the edit template' do
        expect(response).to render_template('edit')
      end

      it 'should not change the database entry' do
        forum.reload
        expect(forum.name).to eq('Forum name')
        expect(forum.description).to eq('Forum description')
      end
    end
  end

  describe '#sticky' do
    let!(:message1) { FactoryBot.create(:message, forum: forum) }
    let!(:message2) { FactoryBot.create(:message, forum: forum) }
    let!(:sticked_message1) {
      FactoryBot.create(:message, forum_id: forum.id,
                                   subject: 'How to',
                                   content: 'How to install this cool app',
                                   sticky: '1',
                                   sticked_on: Time.now - 2.minute)
    }

    let!(:sticked_message2) {
      FactoryBot.create(:message, forum_id: forum.id,
                                   subject: 'FAQ',
                                   content: 'Frequestly asked question',
                                   sticky: '1',
                                   sticked_on:
                                   Time.now - 1.minute)
    }

    describe 'all sticky messages' do
      before do
        expect(@controller).to receive(:authorize)
        get :show, params: { project_id: project.id, id: forum.id }
      end

      it 'renders show' do
        expect(response).to render_template 'show'
      end
      it 'should be displayed on top' do
        expect(assigns[:topics][0].id).to eq(sticked_message1.id)
      end
    end

    describe 'edit a sticky message' do
      before(:each) do
        sticked_message1.sticky = 0
        sticked_message1.save!
      end

      describe 'when sticky is unset from message' do
        before do
          expect(@controller).to receive(:authorize)
          get :show, params: { project_id: project.id, id: forum.id }
        end

        it 'it should not be displayed as sticky message' do
          expect(sticked_message1.sticked_on).to be_nil
          expect(assigns[:topics][0].id).not_to eq(sticked_message1.id)
        end
      end

      describe 'when sticky is set back to message' do
        before do
          sticked_message1.sticky = 1
          sticked_message1.save!

          expect(@controller).to receive(:authorize)
          get :show, params: { project_id: project.id, id: forum.id }
        end

        it 'it should not be displayed on first position' do
          expect(assigns[:topics][0].id).to eq(sticked_message2.id)
        end
      end
    end
  end
end
