#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

require "spec_helper"

RSpec.describe EnterprisesController do
  let(:a_token) { EnterpriseToken.new }

  let(:token_attributes) do
    {
      subscriber: "Foobar",
      mail: "foo@example.org",
      starts_at: Date.today,
      expires_at: nil
    }
  end

  let(:token_object) do
    OpenProject::Token.new token_attributes
  end

  before do
    login_as user
    allow(a_token).to receive(:token_object).and_return(token_object)
  end

  context "with admin" do
    let(:user) { build(:admin) }

    describe "#show" do
      render_views

      context "when token exists" do
        before do
          allow(EnterpriseToken).to receive(:current).and_return(a_token)
          get :show
        end

        shared_examples "it renders the EE overview" do
          it "renders the overview" do
            expect(response).to be_successful
            expect(response).to render_template "show"
            expect(response).to render_template partial: "enterprises/_current"
            expect(response).to render_template partial: "enterprises/_form"
          end
        end

        it_behaves_like "it renders the EE overview"

        context "with version >= 2.0" do
          let(:token_attributes) { super().merge version: "2.0" }

          context "with correct domain", with_settings: { host_name: "community.openproject.com" } do
            let(:token_attributes) { super().merge domain: "community.openproject.com" }

            it_behaves_like "it renders the EE overview"

            it "doesn't show any warnings or errors" do
              expect(controller).not_to set_flash.now
            end
          end

          context "with wrong domain", with_settings: { host_name: "community.openproject.com" } do
            let(:token_attributes) { super().merge domain: "localhost" }

            it_behaves_like "it renders the EE overview"

            it "shows an invalid domain error" do
              expect(controller).to set_flash.now[:error].to(/.*localhost.*does not match.*community.openproject.com/)
            end
          end
        end

        context "with version < 2.0" do
          let(:token_attributes) { super().merge version: "1.0.3" }

          context "with wrong domain", with_settings: { host_name: "community.openproject.com" } do
            let(:token_attributes) { super().merge domain: "localhost" }

            it_behaves_like "it renders the EE overview"

            it "doesn't show any warnings or errors" do
              expect(controller).not_to set_flash.now
            end
          end
        end
      end

      context "when no token exists" do
        before do
          allow(EnterpriseToken).to receive(:current).and_return(nil)
          get :show
        end

        it "still renders #show with form" do
          expect(response).not_to render_template partial: "enterprises/_current"
          expect(response.body).to have_css ".upsale-benefits"
        end
      end
    end

    describe "#create" do
      let(:params) do
        {
          enterprise_token: { encoded_token: "foo" }
        }
      end

      before do
        allow(EnterpriseToken).to receive(:current).and_return(nil)
        allow(EnterpriseToken).to receive(:new).and_return(a_token)
        expect(a_token).to receive(:encoded_token=).with("foo")
        expect(a_token).to receive(:save).and_return(valid)

        post :create, params:
      end

      context "valid token input" do
        let(:valid) { true }

        it "redirects to index" do
          expect(controller).to set_flash[:notice].to I18n.t(:notice_successful_update)
          expect(response).to redirect_to action: :show
        end
      end

      context "invalid token input" do
        let(:valid) { false }

        it "renders with error" do
          expect(response).not_to be_redirect
          expect(response).to render_template "enterprises/show"
        end
      end
    end

    describe "#destroy" do
      context "when a token exists" do
        before do
          expect(EnterpriseToken).to receive(:current).and_return(a_token)
          expect(a_token).to receive(:destroy)

          delete :destroy
        end

        it "redirects to show" do
          expect(controller).to set_flash[:notice].to I18n.t(:notice_successful_delete)
          expect(response).to redirect_to action: :show
        end
      end

      context "when no token exists" do
        before do
          expect(EnterpriseToken).to receive(:current).and_return(nil)
          delete :destroy
        end

        it "renders 404" do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  context "regular user" do
    let(:user) { build(:user) }

    before do
      get :show
    end

    it "is forbidden" do
      expect(response).to have_http_status :forbidden
    end
  end
end
