require_relative "../spec_helper"

RSpec.describe LdapGroups::SynchronizedGroupsController, with_ee: %i[ldap_groups] do
  let(:user) { create(:user) }
  let(:admin) { create(:admin) }

  before do
    allow(User).to receive(:current).and_return(logged_in_user)
  end

  describe "#index" do
    before do
      get :index
    end

    context "when not admin" do
      let(:logged_in_user) { user }

      it "does not give access" do
        expect(response).to have_http_status :forbidden
      end
    end

    context "when admin" do
      let(:logged_in_user) { admin }

      it "renders the page" do
        expect(response).to be_successful
        expect(response).to render_template "index"
      end
    end
  end

  describe "#show" do
    context "when not admin" do
      let(:logged_in_user) { user }
      let(:id) { "whatever" }

      it "does not give access" do
        get :show, params: { ldap_group_id: id }
        expect(response).to have_http_status :forbidden
      end
    end

    context "when admin" do
      let(:logged_in_user) { admin }

      context "when no entry exists" do
        let(:id) { "foo" }

        it "renders 404" do
          get :show, params: { ldap_group_id: id }
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when entry exists" do
        let!(:group) { build_stubbed(:ldap_synchronized_group) }
        let(:id) { "foo" }

        it "renders the page" do
          expect(LdapGroups::SynchronizedGroup)
              .to receive(:find)
              .with("foo")
              .and_return(group)

          get :show, params: { ldap_group_id: id }
          expect(response).to be_successful
          expect(response).to render_template "show"
        end
      end
    end
  end

  describe "#new" do
    context "when not admin" do
      let(:logged_in_user) { user }

      it "does not give access" do
        get :new
        expect(response).to have_http_status :forbidden
      end
    end

    context "when admin" do
      let(:logged_in_user) { admin }

      it "renders the page" do
        get :new
        expect(response).to be_successful
        expect(response).to render_template "new"
      end
    end
  end

  describe "#create" do
    let(:save_result) { false }

    before do
      allow_any_instance_of(LdapGroups::SynchronizedGroup).to receive(:save).and_return(save_result)
      post :create, params: { synchronized_group: params }
    end

    context "when not admin" do
      let(:logged_in_user) { user }
      let(:params) { {} }

      it "does not give access" do
        expect(response).to have_http_status :forbidden
      end
    end

    context "when admin" do
      let(:logged_in_user) { admin }

      context "with invalid params" do
        let(:params) { {} }

        it "renders 400" do
          expect(response).to have_http_status(:bad_request)
        end
      end

      context "with valid params" do
        let(:params) { { ldap_auth_source_id: 1, group_id: 1, dn: "cn=foo,ou=groups,dc=example,dc=com" } }

        context "and saving succeeds" do
          let(:save_result) { true }

          it "renders 200" do
            expect(flash[:notice]).to be_present
            expect(response).to redirect_to action: :index
          end
        end

        context "and saving fails" do
          it "renders new page" do
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response).to render_template :new
          end
        end
      end
    end
  end

  describe "#destroy_info" do
    context "when not admin" do
      let(:logged_in_user) { user }
      let(:id) { "whatever" }

      it "does not give access" do
        get :destroy_info, params: { ldap_group_id: id }
        expect(response).to have_http_status :forbidden
      end
    end

    context "when admin" do
      let(:logged_in_user) { admin }

      context "when no entry exists" do
        let(:id) { "foo" }

        it "renders 404" do
          get :destroy_info, params: { ldap_group_id: id }
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when entry exists" do
        let!(:group) { build_stubbed(:ldap_synchronized_group) }
        let(:id) { "foo" }

        it "renders the page" do
          expect(LdapGroups::SynchronizedGroup)
              .to receive(:find)
              .with("foo")
              .and_return(group)

          get :destroy_info, params: { ldap_group_id: id }
          expect(response).to be_successful
          expect(response).to render_template "destroy_info"
        end
      end
    end
  end

  describe "#destroy" do
    context "when not admin" do
      let(:logged_in_user) { user }
      let(:id) { "whatever" }

      it "does not give access" do
        delete :destroy, params: { ldap_group_id: id }
        expect(response).to have_http_status :forbidden
      end
    end

    context "when admin" do
      let(:logged_in_user) { admin }

      context "when no entry exists" do
        let(:id) { "foo" }

        it "renders 404" do
          delete :destroy, params: { ldap_group_id: id }
          expect(response).to have_http_status(:not_found)
        end
      end

      context "when entry exists" do
        let!(:group) { build_stubbed(:ldap_synchronized_group) }
        let(:id) { "foo" }

        before do
          expect(LdapGroups::SynchronizedGroup)
              .to receive(:find)
              .with("foo")
              .and_return(group)

          expect(group)
            .to receive(:destroy)
            .and_return(destroy_result)
        end

        context "when deletion succeeds" do
          let(:destroy_result) { true }

          it "redirects to index" do
            delete :destroy, params: { ldap_group_id: id }
            expect(flash[:notice]).to be_present
            expect(response).to redirect_to action: :index
          end
        end

        context "when deletion fails" do
          let(:destroy_result) { false }

          it "redirects to index" do
            delete :destroy, params: { ldap_group_id: id }
            expect(flash[:error]).to be_present
            expect(response).to redirect_to action: :index
          end
        end
      end
    end
  end
end
