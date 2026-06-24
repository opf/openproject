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

RSpec.describe "my", :js do
  let(:user_password) { "bob" * 4 }
  let!(:string_cf) { create(:user_custom_field, :string, name: "Hobbies", is_required: false) }
  let(:user) do
    create(:user,
           mail: "old@mail.com",
           login: "bob",
           password: user_password,
           password_confirmation: user_password)
  end

  ##
  # Expectations for a successful account change
  def expect_changed!
    expect(page).to have_content I18n.t(:notice_account_updated)
    expect(page).to have_content I18n.t(:notice_account_other_session_expired)

    # expect session to be removed
    expect(Sessions::UserSession.for_user(user).where(session_id: "other").count).to eq 0

    user.reload
    expect(user.mail).to eq "foo@mail.com"
    expect(user.name).to eq "Foo Bar"
  end

  before do
    # Use a fresh AR instance to avoid leaking virtual attributes (e.g. password accessors)
    # between examples into RequestStore.current_user.
    login_as User.find(user.id)

    # Create dangling session
    session = Sessions::SqlBypass.new data: { user_id: user.id }, session_id: "other"
    session.save

    expect(Sessions::UserSession.for_user(user).where(session_id: "other").count).to eq 1
  end

  shared_examples "common tests for normal and LDAP user" do
    describe "Language and Region" do
      before do
        visit my_locale_path
      end

      context "with a default time zone", with_settings: { user_default_timezone: "Asia/Tokyo" } do
        it "override user time zone" do
          expect(user.pref.time_zone).to eq "Asia/Tokyo"
          expect(page).to have_heading "Language and region"

          expect(page).to have_select "Time zone", selected: "(UTC+09:00) Tokyo"
          select "(UTC+01:00) Paris", from: "Time zone"
          click_on "Save"

          expect_and_dismiss_flash type: :success, message: "Account was successfully updated."

          user.reload
          expect(page).to have_select "Time zone", selected: "(UTC+01:00) Paris"
          expect(user.pref.time_zone).to eq "Europe/Paris"
        end
      end

      it "updates user language" do
        expect(user.language).to eq "en"
        expect(page).to have_heading "Language and region"

        expect(page).to have_select "Language", selected: "English"
        select "Español", from: "Language"
        click_on "Save"

        expect_and_dismiss_flash type: :success, message: "Cuenta se actualizó correctamente."

        user.reload
        expect(page).to have_select "Idioma", selected: "Español"
        expect(user.language).to eq "es"
      end

      it "updates user language with change visible on navigating to other settings (regression #66951)" do
        expect(user.language).to eq "en"
        expect(page).to have_heading "Language and region"

        expect(page).to have_select "Language", selected: "English"
        select "Português do brasil", from: "Language"
        click_on "Save"

        expect_and_dismiss_flash type: :success, message: "Conta foi atualizada com sucesso."

        expect(page).to have_select "Idioma", selected: "Português do brasil"

        within "#main-menu" do
          click_on "Tokens de acesso"
        end

        expect(page).to have_heading "Tokens de acesso"
        expect(page).to have_heading "iCalendar para reuniões"
      end
    end
  end

  describe "non-editable custom fields" do
    let!(:readonly_cf) do
      create(:user_custom_field, :string, name: "Employee ID", editable: false)
    end

    it "renders them read-only on the account page" do
      visit my_account_path

      expect(page).to have_field("Employee ID", disabled: true)
    end
  end

  context "user" do
    describe "#account" do
      let(:dialog) { Components::PasswordConfirmationDialog.new }

      before do
        visit my_account_path

        fill_in "user[mail]", with: "foo@mail.com"
        fill_in "user[firstname]", with: "Foo"
        fill_in "user[lastname]", with: "Bar"
        click_on "Update profile"
      end

      context "when confirmation disabled",
              with_config: { internal_password_confirmation: false } do
        it "does not request confirmation" do
          expect_changed!
        end
      end

      context "when confirmation required",
              with_config: { internal_password_confirmation: true } do
        it "requires the password for a regular user" do
          dialog.confirm_flow_with(user_password)
          expect_changed!
        end

        it "declines the change when invalid password is given" do
          dialog.confirm_flow_with(user_password + "INVALID", should_fail: true)

          user.reload
          expect(user.mail).to eq("old@mail.com")
        end

        context "as admin" do
          shared_let(:admin) { create(:admin) }
          let(:user) { admin }

          it "requires the password" do
            dialog.confirm_flow_with("adminADMIN!")
            expect_changed!
          end
        end
      end
    end

    include_examples "common tests for normal and LDAP user"
  end

  # Without password confirmation the test doesn't try to connect to the LDAP:
  context "LDAP user", with_config: { internal_password_confirmation: false } do
    let(:ldap_auth_source) { create(:ldap_auth_source) }
    let(:user) do
      create(:user,
             mail: "old@mail.com",
             login: "bob",
             ldap_auth_source:)
    end

    describe "#account" do
      before do
        visit my_account_path
      end

      it "does not allow change of name and email but other fields can be changed" do
        expect(page).to have_field("user[mail]", readonly: true)
        expect(page).to have_field("user[firstname]", readonly: true)
        expect(page).to have_field("user[lastname]", readonly: true)

        expect(page).to have_text(I18n.t("user.text_change_disabled_for_provider_login"), count: 3)

        fill_in "Hobbies", with: "Ruby, DCS"
        click_on "Update profile"

        expect(page).to have_content I18n.t(:notice_account_updated)

        user.reload
        expect(user.custom_values.find_by(custom_field_id: string_cf).value).to eql "Ruby, DCS"
      end
    end

    include_examples "common tests for normal and LDAP user"
  end
end
