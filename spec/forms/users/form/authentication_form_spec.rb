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

RSpec.describe Users::Form::AuthenticationForm, type: :forms do
  include_context "with rendered form"

  before do
    User.current = build_stubbed(:admin)
    create(:ldap_auth_source)
  end

  let(:params) do
    { user: model,
      render_auth_source:,
      render_password:,
      render_no_login_message:,
      render_external_auth:,
      assign_random_password_checked: false }
  end
  let(:render_auth_source) { true }
  let(:render_password) { true }
  let(:render_no_login_message) { false }
  let(:render_external_auth) { false }

  context "with only the auth source select, for a new user" do
    let(:model) { User.new }
    let(:render_password) { false }

    it "renders the auth source select with the toggle action and a hidden login group" do
      expect(page).to have_select("user[ldap_auth_source_id]")
      expect(page).to have_css("[data-action~='admin--users#toggleAuthenticationFields']")
      expect(page).to have_css("[data-admin--users-target='authSourceFields'][hidden]", visible: :all)
      expect(page).to have_field("user[login]", visible: :all)
    end
  end

  context "with only the auth source select, for a persisted user" do
    let(:model) { build_stubbed(:user) }
    let(:render_password) { false }

    it "renders the select inside a titled Authentication fieldset and no hidden login" do
      expect(page).to have_select("user[ldap_auth_source_id]")
      expect(page).to have_css("fieldset", text: /#{I18n.t(:label_authentication)}/i)
      expect(page).to have_no_css("[data-admin--users-target='authSourceFields']", visible: :all)
    end
  end

  context "with only the password settings" do
    let(:model) { build_stubbed(:user) }
    let(:render_auth_source) { false }

    before { allow(model).to receive(:change_password_allowed?).and_return(true) }

    it "renders one wrapper carrying the three controllers and the passwordFields target" do
      expect(page).to have_css(
        "[data-controller~='disable-when-checked'][data-controller~='password-force-change']" \
        "[data-controller~='password-requirements'][data-admin--users-target='passwordFields']",
        visible: :all
      )
    end

    it "renders the password fields with their ids and password type" do
      expect(page).to have_field("user[password]", type: "password", visible: :all)
      expect(page).to have_field("user[password_confirmation]", type: "password", visible: :all)
      expect(page).to have_css("#user_password", visible: :all)
    end

    it "renders the unscoped send_information checkbox and the scoped flags" do
      expect(page).to have_field("send_information", visible: :all)
      expect(page).to have_css("#send_information", visible: :all)
      expect(page).to have_field("user[assign_random_password]", visible: :all)
      expect(page).to have_field("user[force_password_change]", visible: :all)
    end
  end

  context "with both the auth source select and the password settings" do
    let(:model) { build_stubbed(:user) }

    before { allow(model).to receive(:change_password_allowed?).and_return(true) }

    it "nests both the select and the password fields inside the Authentication fieldset" do
      expect(page).to have_css("fieldset", text: /#{I18n.t(:label_authentication)}/i)
      expect(page).to have_css("fieldset select[name='user[ldap_auth_source_id]']")
      expect(page).to have_css("fieldset input[name='user[password]']", visible: :all)
    end
  end

  context "with the no-login notice" do
    let(:model) { build_stubbed(:user) }
    let(:render_auth_source) { false }
    let(:render_password) { false }
    let(:render_no_login_message) { true }

    it "renders the cannot-login notice as an InlineMessage inside the Authentication fieldset" do
      expect(page).to have_css("fieldset .InlineMessage", text: I18n.t("user.no_login"))
    end
  end

  context "with external authentication" do
    let(:model) { create(:user, identity_url: "saml:user-id") }
    let(:render_auth_source) { false }
    let(:render_password) { false }
    let(:render_external_auth) { true }

    it "renders the provider read-only inside the Authentication fieldset and no auth inputs" do
      expect(page).to have_css("fieldset", text: /#{I18n.t(:label_authentication)}/i)
      expect(page).to have_text(I18n.t("user.authentication_provider"))
      expect(page).to have_no_select("user[ldap_auth_source_id]")
    end
  end
end
