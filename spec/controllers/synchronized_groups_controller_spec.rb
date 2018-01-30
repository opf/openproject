require_relative '../spec_helper'

describe ::LdapGroups::SynchronizedGroupsController, with_groups_ee: true, type: :controller do
  let(:user) { FactoryGirl.create :user }
  let(:admin) { FactoryGirl.create :admin }

  before do
    allow(User).to receive(:current).and_return(logged_in_user)
  end

  describe '#index' do
    before do
      get :index
    end

    context 'when not admin' do
      let(:logged_in_user) { user }

      it 'does not give access' do
        expect(response.status).to eq 403
      end
    end

    context 'when admin' do
      let(:logged_in_user) { admin }

      it 'renders the page' do
        expect(response).to be_success
        expect(response).to render_template 'index'
      end
    end
  end

  describe '#show' do
    context 'when not admin' do
      let(:logged_in_user) { user }
      let(:id) { 'whatever' }

      it 'does not give access' do
        get :show, params: { ldap_group_id: id }
        expect(response.status).to eq 403
      end
    end

    context 'when admin' do
      let(:logged_in_user) { admin }

      context 'when no entry exists' do
        let(:id) { 'foo' }

        it 'renders 404' do
          get :show, params: { ldap_group_id: id }
          expect(response.status).to eq(404)
        end
      end

      context 'when entry exists' do
        let!(:group) { FactoryGirl.build_stubbed :ldap_synchronized_group }
        let(:id) { 'foo' }

        it 'renders the page' do
          expect(::LdapGroups::SynchronizedGroup)
              .to receive(:find)
              .with('foo')
              .and_return(group)

          get :show, params: { ldap_group_id: id }
          expect(response).to be_success
          expect(response).to render_template 'show'
        end
      end
    end
  end

  describe '#new' do
    context 'when not admin' do
      let(:logged_in_user) { user }

      it 'does not give access' do
        get :new
        expect(response.status).to eq 403
      end
    end

    context 'when admin' do
      let(:logged_in_user) { admin }

      it 'renders the page' do
        get :new
        expect(response).to be_success
        expect(response).to render_template 'new'
      end
    end
  end

  describe '#create' do
    let(:save_result) { false }
    before do
      allow_any_instance_of(::LdapGroups::SynchronizedGroup).to receive(:save).and_return(save_result)
      post :create, params: { synchronized_group: params }
    end

    context 'when not admin' do
      let(:logged_in_user) { user }
      let(:params) { {} }

      it 'does not give access' do
        expect(response.status).to eq 403
      end
    end

    context 'when admin' do
      let(:logged_in_user) { admin }

      context 'with invalid params' do
        let(:params) { {} }

        it 'renders 400' do
          expect(response.status).to eq(400)
        end
      end

      context 'with valid params' do
        let(:params) { { auth_source_id: 1, group_id: 1, entry: 'foo' } }

        context 'and saving succeeds' do
          let(:save_result) { true }
          it 'renders 200' do
            expect(flash[:notice]).to be_present
            expect(response).to redirect_to action: :index
          end
        end

        context 'and saving fails' do
          it 'renders new page' do
            expect(response.status).to eq(200)
            expect(response).to render_template :new
          end
        end
      end
    end
  end

  describe '#destroy_info' do
    context 'when not admin' do
      let(:logged_in_user) { user }
      let(:id) { 'whatever' }

      it 'does not give access' do
        get :destroy_info, params: { ldap_group_id: id }
        expect(response.status).to eq 403
      end
    end

    context 'when admin' do
      let(:logged_in_user) { admin }

      context 'when no entry exists' do
        let(:id) { 'foo' }

        it 'renders 404' do
          get :destroy_info, params: { ldap_group_id: id }
          expect(response.status).to eq(404)
        end
      end

      context 'when entry exists' do
        let!(:group) { FactoryGirl.build_stubbed :ldap_synchronized_group }
        let(:id) { 'foo' }

        it 'renders the page' do
          expect(::LdapGroups::SynchronizedGroup)
              .to receive(:find)
              .with('foo')
              .and_return(group)

          get :destroy_info, params: { ldap_group_id: id }
          expect(response).to be_success
          expect(response).to render_template 'destroy_info'
        end
      end
    end
  end

  describe '#destroy' do
    context 'when not admin' do
      let(:logged_in_user) { user }
      let(:id) { 'whatever' }

      it 'does not give access' do
        delete :destroy, params: { ldap_group_id: id }
        expect(response.status).to eq 403
      end
    end

    context 'when admin' do
      let(:logged_in_user) { admin }

      context 'when no entry exists' do
        let(:id) { 'foo' }

        it 'renders 404' do
          delete :destroy, params: { ldap_group_id: id }
          expect(response.status).to eq(404)
        end
      end

      context 'when entry exists' do
        let!(:group) { FactoryGirl.build_stubbed :ldap_synchronized_group }
        let(:id) { 'foo' }

        before do
          expect(::LdapGroups::SynchronizedGroup)
              .to receive(:find)
              .with('foo')
              .and_return(group)

          expect(group)
            .to receive(:destroy)
            .and_return(destroy_result)
        end

        context 'when deletion succeeds' do
          let(:destroy_result) { true }

          it 'redirects to index' do
            delete :destroy, params: { ldap_group_id: id }
            expect(flash[:notice]).to be_present
            expect(response).to redirect_to action: :index
          end
        end

        context 'when deletion fails' do
          let(:destroy_result) { false }

          it 'redirects to index' do
            delete :destroy, params: { ldap_group_id: id }
            expect(flash[:error]).to be_present
            expect(response).to redirect_to action: :index
          end
        end
      end
    end
  end
end
