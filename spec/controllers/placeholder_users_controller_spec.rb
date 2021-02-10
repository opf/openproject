#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'work_package'

describe PlaceholderUsersController, type: :controller do
  let(:current_user) { FactoryBot.build(:admin) }
  let(:placeholder_user) { FactoryBot.create(:placeholder_user) }

  shared_examples 'do not allow non-admins' do
    let(:current_user) { FactoryBot.build(:user) }

    it 'responds with unauthorized status' do
      expect(response).to_not be_successful
      expect(response.status).to eq 403
    end
  end

  describe 'GET new' do
    before do
      as_logged_in_user(current_user) do
        get :new
      end
    end

    context 'as admin' do
      it 'renders the new template' do
        expect(response).to be_successful
        expect(response).to render_template 'placeholder_users/new'
        expect(assigns(:placeholder_user)).to be_present
      end
    end

    context 'not as admin' do
      let(:current_user) { FactoryBot.build(:user) }

      it 'responds with unauthorized status' do
        expect(response).to_not be_successful
        expect(response.status).to eq 403
      end
    end
  end

  describe 'GET index' do
    before do
      as_logged_in_user(current_user) do
        get :index
      end
    end

    context 'as admin' do
      it 'renders the index template' do
        expect(response).to be_successful
        expect(response).to render_template 'placeholder_users/index'
        expect(assigns(:placeholder_users)).to be_empty
        expect(assigns(:groups)).to be_empty
      end
    end

    context 'not as admin' do
      let(:current_user) { FactoryBot.build(:user) }

      it_behaves_like 'do not allow non-admins'
    end
  end

  describe 'GET show' do
    shared_examples 'renders the show template' do
      it 'renders the show template' do
        expect(response).to be_successful
        expect(response).to render_template 'placeholder_users/show'
        expect(assigns(:placeholder_user)).to be_present
        expect(assigns(:memberships)).to be_empty
      end
    end

    before do
      as_logged_in_user(current_user) do
        get :show, params: { id: placeholder_user.id }
      end
    end

    context 'as admin' do
      it_behaves_like 'renders the show template'
    end

    context 'not as admin' do
      let(:current_user) { FactoryBot.build(:user) }

      # normal users can also checkout the profile page of placeholder user.
      it_behaves_like 'renders the show template'
    end
  end

  describe 'GET edit' do
    shared_examples 'renders the edit template' do
      it 'renders the show template' do
        expect(response).to be_successful
        expect(response).to render_template "placeholder_users/edit"
        expect(assigns(:placeholder_user)).to eql(placeholder_user)
        expect(assigns(:membership)).to be_present
        expect(assigns(:individual_principal)).to eql(placeholder_user)
      end
    end

    before do
      as_logged_in_user(current_user) do
        get :edit, params: { id: placeholder_user.id }
      end
    end

    context 'as admin' do
      it_behaves_like 'renders the edit template'
    end

    context 'not as admin' do
      let(:current_user) { FactoryBot.build(:user) }

      # normal users can also checkout the profile page of placeholder user.
      it_behaves_like 'do not allow non-admins'
    end
  end

  describe 'POST create' do
    let(:params) do
      {
        placeholder_user: {
          name: 'UX Developer'
        }
      }
    end

    before do
      as_logged_in_user(current_user) do
        post :create, params: params
      end
    end

    context 'as admin' do
      it 'should be assigned their new values' do
        user_from_db = PlaceholderUser.last
        expect(user_from_db.name).to eq('UX Developer')
      end

      it 'should show a success notice' do
        expect(flash[:notice]).to eql(I18n.t(:notice_successful_create))
      end

      it 'should not send an email' do
        expect(ActionMailer::Base.deliveries.empty?).to be_truthy
      end

      context 'when user chose to directly create the next placeholder user' do
        let(:params) do
          {
            placeholder_user: {
                name: 'UX Developer'
            },
            continue: true
          }
        end

        it 'should redirect to the new page' do
          expect(response).to redirect_to(new_placeholder_user_url)
        end
      end

      context 'when user chose to NOT directly create the next placeholder user' do
        let(:params) do
          {
            placeholder_user: {
              name: 'UX Developer'
            }
          }
        end

        it 'should redirect to the edit page' do
          user_from_db = PlaceholderUser.last
          expect(response).to redirect_to(edit_placeholder_user_url(user_from_db))
        end
      end
    end

    it_behaves_like 'do not allow non-admins'

    context 'invalid params' do
      let(:params) do
        {
          placeholder_user: {
            name: 'x' * 300 # Name is too long
          }
        }
      end

      it 'should render the edit form with a validation error message' do
        expect(assigns(:'placeholder_user').errors.messages[:name].first).to include('is too long')
        expect(response).to render_template 'placeholder_users/new'
      end
    end
  end

  describe 'PUT update' do
    let(:params) do
      {
        id: placeholder_user.id,
        placeholder_user: {
          name: 'UX Guru'
        }
      }
    end

    before do
      as_logged_in_user(current_user) do
        put :update, params: params
      end
    end

    context 'as admin' do
      it 'should redirect to the edit page' do
        expect(response).to redirect_to(edit_placeholder_user_url(placeholder_user))
      end

      it 'should be assigned their new values' do
        user_from_db = PlaceholderUser.find(placeholder_user.id)
        expect(user_from_db.name).to eq('UX Guru')
      end

      it 'should not send an email' do
        expect(ActionMailer::Base.deliveries.empty?).to be_truthy
      end
    end

    it_behaves_like 'do not allow non-admins'

    context 'invalid params' do
      let(:params) do
        {
          id: placeholder_user.id,
          placeholder_user: {
            name: 'x' * 300 # Name is too long
          }
        }
      end

      it 'should render the edit form with a validation error message' do
        expect(assigns(:'placeholder_user').errors.messages[:name].first).to include('is too long')
        expect(response).to render_template 'placeholder_users/edit'
      end
    end
  end

  describe 'POST destroy' do
    pending 'Admins can destroy placeholder users'
    pending 'Non admins cannot destroy placeholder users'
  end
end

