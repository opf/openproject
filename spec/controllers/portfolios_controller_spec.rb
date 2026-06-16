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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe PortfoliosController do
  shared_let(:admin) { create(:admin) }
  shared_let(:restricted_user) { create(:user) }

  let(:user) { admin }

  describe "#new" do
    before do
      login_as user
      get :new, params: { parent_id: parent&.id, template_id: template&.id, workspace_type: }
    end

    shared_examples_for "successful requests" do
      context "without a parent" do
        let(:parent) { nil }

        context "without a template" do
          let(:template) { nil }

          it_behaves_like "successful request"
        end

        context "with a template" do
          let(:template) { create(:template_project) }

          it_behaves_like "successful request"
        end
      end

      context "with a parent" do
        let(:parent) { create(:project) }

        context "without a template" do
          let(:template) { nil }

          it_behaves_like "successful request"
        end

        context "with a template" do
          let(:template) { create(:template_project) }

          it_behaves_like "successful request"
        end
      end
    end

    shared_examples_for "successful request" do
      it "renders 'new'", :aggregate_failures do
        expect(response).to be_successful
        expect(assigns(:new_project)).to be_a_new(Project)
        expect(assigns(:parent)).to eq parent
        expect(assigns(:template)).to eq template
        expect(response).to render_template "new"
      end
    end

    let(:workspace_type) { "portfolio" }

    let(:template) { nil }
    let(:parent) { nil }

    context "as an admin" do
      it_behaves_like "successful request"
    end

    context "as a non-admin with global add_portfolios permission" do
      let(:user) { create(:user, global_permissions: [:add_portfolios]) }

      it_behaves_like "successful request"
    end

    context "as a non-admin without add_portfolios permission" do
      let(:user) { create(:user) }

      it "returns 403 Not Authorized" do
        expect(response).not_to be_successful
        expect(response).to have_http_status :forbidden
      end
    end

    context "when not being logged in but login is required", with_settings: { login_required: true } do
      let(:user) { User.anonymous }
      let(:workspace_type) { "portfolio" }
      let(:parent) { build_stubbed(:project) }
      let(:template) { build_stubbed(:project) }

      it "redirects to the sign in page with the parameters provided in the back url" do
        expect(response).to be_redirect
        expect(response).to redirect_to signin_path(back_url: new_portfolio_url(parent_id: parent.id,
                                                                                template_id: template.id))
      end
    end
  end

  describe "#index" do
    shared_let(:portfolio_a) { create(:portfolio, name: "Portfolio A", public: false, active: true) }
    shared_let(:portfolio_b) { create(:portfolio, name: "Portfolio B", public: false, active: true) }
    shared_let(:portfolio_c) { create(:portfolio, name: "Portfolio C", public: true, active: true) }
    shared_let(:portfolio_d) { create(:portfolio, name: "Portfolio D", public: true, active: false) }

    before do
      login_as(user)
      get "index"
    end

    shared_examples_for "successful index" do
      it "is success" do
        expect(response).to be_successful
      end

      it "renders the index template" do
        expect(response).to render_template "index"
      end
    end

    shared_examples_for "forbidden index request" do
      it "returns 403 Forbidden" do
        expect(response).not_to be_successful
        expect(response).to have_http_status :forbidden
      end
    end

    it_behaves_like "successful index"

    it "includes active portfolios in the result" do
      query = assigns(:query)
      expect(query).to be_a_new(ProjectQuery)
      expect(query).to be_valid

      expect(query.results.portfolio).to eq([portfolio_a, portfolio_b, portfolio_c])
    end

    context "with a user who does not have permission to see the portfolio module" do
      let(:user) { restricted_user }

      it_behaves_like "forbidden index request"
    end

    context "with a user who has permission to see the portfolio module" do
      context "when the user has the global add_portfolios permission" do
        let(:user) { create(:user, global_permissions: [:add_portfolios]) }

        it_behaves_like "successful index"
      end

      context "when the user has a view_project permission on an active portfolio" do
        let(:user) do
          create(:user, member_with_permissions: { portfolio_a => [:view_project] })
        end

        it_behaves_like "successful index"
      end

      context "when the user has a view_project permission on an inactive portfolio" do
        let(:user) do
          create(:user, member_with_permissions: { portfolio_d => [:view_project] })
        end

        it_behaves_like "forbidden index request"
      end
    end
  end
end
