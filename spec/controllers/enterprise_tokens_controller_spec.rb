# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe EnterpriseTokensController do
  include EnterpriseTokenFactory

  let(:token_attributes) do
    {
      subscriber: "Foobar subscriber",
      mail: "foo@example.org",
      starts_at: Date.current,
      expires_at: nil
    }
  end

  before do
    login_as user
  end

  context "with an admin user" do
    let(:user) { build(:admin) }

    describe "#index" do
      render_views

      context "when an Enterprise token is active" do
        let!(:enterprise_token) { create_enterprise_token(**token_attributes) }

        before do
          get :index
        end

        shared_examples "it renders the enterprise tokens list" do
          it "renders the enterprise tokens list" do
            expect(response).to be_successful
            expect(response).to render_template "index"
            expect(response.body).to have_text(enterprise_token.subscriber)
          end
        end

        include_examples "it renders the enterprise tokens list"

        context "with version >= 2.0" do
          let(:token_attributes) { super().merge version: "2.0" }

          context "with correct domain", with_settings: { host_name: "community.openproject.com" } do
            let(:token_attributes) { super().merge domain: "community.openproject.com" }

            include_examples "it renders the enterprise tokens list"

            it "displays the domain name" do
              expect(response.body).to have_text(token_attributes[:domain])
            end
          end

          context "with wrong domain", with_settings: { host_name: "community.openproject.com" } do
            let(:token_attributes) { super().merge domain: "non-matching-domain.openproject.com" }

            include_examples "it renders the enterprise tokens list"

            it "displays the domain with an invalid message", skip: "TODO: there is no warning displayed yet" do
              expect(controller).to set_flash.now[:error].to(/.*localhost.*does not match.*community.openproject.com/)
            end
          end
        end

        context "with version < 2.0" do
          let(:token_attributes) { super().merge version: "1.0.3" }

          context "with wrong domain", with_settings: { host_name: "community.openproject.com" } do
            let(:token_attributes) { super().merge domain: "localhost" }

            include_examples "it renders the enterprise tokens list"

            it "doesn't show any warnings or errors", skip: "TODO: there is no warning displayed yet" do
              expect(controller).not_to set_flash.now
            end
          end
        end
      end

      context "when no token exists" do
        before do
          get :index
        end

        it "renders a perks page", skip: "TODO" do
          expect(response.body).to have_css ".upsell-benefits"
        end
      end
    end

    describe "#create" do
      let(:encoded_token) { "foo" }
      let(:params) do
        {
          enterprise_token: { encoded_token: }
        }
      end
      let(:format) { nil }

      before do
        mock_token_object(encoded_token, **token_attributes)

        post :create, params:, format:
      end

      context "with valid token input" do
        let(:token_attributes) { super().merge(domain: Setting.host_name) }

        # TODO: is it still relevant to test html rendering?
        it "saves the token and redirects to index" do
          expect(EnterpriseToken.count).to eq 1
          expect(controller).to set_flash[:notice].to I18n.t(:notice_successful_update)
          expect(response).to redirect_to action: :index
        end
      end

      context "with unreadable token input" do
        let(:token_attributes) { super().merge(domain: "non-matching-domain.openproject.com") }
        let(:params) do
          {
            enterprise_token: { encoded_token: "I am an unreadable token 🙈" }
          }
        end

        # TODO: is it still relevant to test html rendering?
        it "renders with error" do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template "enterprise_tokens/index"
        end

        context "with turbo stream" do
          let(:format) { :turbo_stream }

          it "renders the form with an error message for the unreadable token" do
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response).to have_turbo_stream action: "update", target: "admin-enterprise-tokens-form-component"
            expected_error_message = I18n.t("activerecord.errors.models.enterprise_token.unreadable")
            expect(response.body).to include(ERB::Util.html_escape(expected_error_message))
          end
        end
      end

      context "with token with invalid domain" do
        let(:token_attributes) { super().merge(domain: "non-matching-domain.openproject.com") }

        # TODO: is it still relevant to test html rendering?
        it "renders with error" do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template "enterprise_tokens/index"
        end

        context "with turbo stream" do
          let(:format) { :turbo_stream }

          it "renders the form with an error message for the invalid domain" do
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response).to have_turbo_stream action: "update", target: "admin-enterprise-tokens-form-component"
            expect(response.body).to include("Domain is invalid")
          end
        end
      end
    end

    describe "#destroy" do
      context "when a token exists" do
        before do
          enterprise_token = create_enterprise_token(**token_attributes)

          delete :destroy, params: { id: enterprise_token.id }
        end

        it "redirects to index" do
          expect(controller).to set_flash[:notice].to I18n.t(:notice_successful_delete)
          expect(response).to redirect_to action: :index
        end
      end

      context "when no token exists" do
        before do
          delete :destroy, params: { id: 42 }
        end

        it "renders 404" do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  context "with a regular user" do
    let(:user) { build(:user) }

    describe "#index" do
      before do
        get :index
      end

      it "is forbidden" do
        expect(response).to have_http_status :forbidden
      end
    end
  end
end
