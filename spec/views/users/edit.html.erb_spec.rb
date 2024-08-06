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

RSpec.describe "users/edit" do
  let(:admin) { build(:admin) }

  before do
    # The url_for is missing the users id that is usually taken
    # from request parameters
    controller.request.path_parameters[:id] = user.id
    view.extend(Gon::ControllerHelpers)
  end

  context "authentication provider" do
    let(:user) do
      build(:user, id: 1, # id is required to create route to edit
                   identity_url: "test_provider:veryuniqueid")
    end

    before do
      assign(:user, user)
      assign(:auth_sources, [])

      without_partial_double_verification do
        allow(view).to receive(:current_user).and_return(admin)
      end
    end

    it "shows the authentication provider" do
      render

      expect(rendered).to include("Test Provider")
    end

    it "does not show a no-login warning when password login is disabled" do
      allow(OpenProject::Configuration).to receive(:disable_password_login).and_return(true)
      render

      expect(rendered).not_to include I18n.t("user.no_login")
    end
  end

  context "with an invited user" do
    let(:user) { build_stubbed(:invited_user) }

    before do
      assign(:user, user)
      assign(:auth_sources, [])
    end

    context "for an admin" do
      before do
        without_partial_double_verification do
          allow(view).to receive(:current_user).and_return(admin)
        end
        render
      end

      it "renders the resend invitation button" do
        expect(rendered).to include I18n.t(:label_send_invitation)
      end
    end

    context "for a non-admin with manage_user global permission" do
      let(:non_admin) { create(:user, global_permissions: [:manage_user]) }

      before do
        without_partial_double_verification do
          allow(view).to receive(:current_user).and_return(non_admin)
        end
        render
      end

      it "does not render the resend invitation button" do
        expect(rendered).not_to include I18n.t(:label_send_invitation)
      end
    end
  end

  context "with a normal (not invited) user" do
    let(:user) { create(:user) }

    before do
      assign(:user, user)
      assign(:auth_sources, [])

      without_partial_double_verification do
        allow(view).to receive(:current_user).and_return(admin)
      end
      render
    end

    it "also renders the resend invitation button" do
      expect(rendered).to include I18n.t(:label_send_invitation)
    end
  end

  context "with password-based login" do
    let(:user) { build(:user, id: 42) }

    before do
      assign :user, user
      assign :auth_sources, []

      without_partial_double_verification do
        allow(view).to receive(:current_user).and_return(admin)
      end
    end

    context "with password login disabled" do
      before do
        allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(true)
      end

      it "warns that the user cannot login" do
        render

        expect(rendered).to include I18n.t("user.no_login")
      end

      context "with auth sources" do
        let(:auth_sources) { create_list(:ldap_auth_source, 1) }

        before do
          assign :auth_sources, auth_sources
        end

        it "does not show the auth source selection" do
          render

          expect(rendered).to have_no_css("#user_auth_source_id")
        end
      end
    end

    context "with password login enabled" do
      before do
        allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(false)
      end

      it "shows password options" do
        render

        expect(rendered).to have_text I18n.t("user.assign_random_password")
      end

      context "with auth sources" do
        let(:auth_sources) { create_list(:ldap_auth_source, 1) }

        before do
          assign :auth_sources, auth_sources
        end

        it "shows the auth source selection" do
          render

          expect(rendered).to have_css("#user_ldap_auth_source_id")
        end
      end

      context "with password choice enabled" do
        before do
          expect(OpenProject::Configuration)
            .to receive(:disable_password_choice?)
            .and_return(false)
        end

        it "shows the password and password confirmation fields" do
          render

          within "#password_fields" do
            expect(rendered).to have_text("Password")
            expect(rendered).to have_text("Confirmation")
          end
        end
      end

      context "with password choice disabled" do
        before do
          expect(OpenProject::Configuration).to receive(:disable_password_choice?).and_return(true)
        end

        it "doesn't show the password and password confirmation fields" do
          render

          within "#password_fields" do
            expect(rendered).to have_no_text("Password")
            expect(rendered).to have_no_text("Password confirmation")
          end
        end
      end
    end
  end
end
