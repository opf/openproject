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

RSpec.describe "create users" do
  shared_let(:admin) { create(:admin) }
  let(:current_user) { admin }
  let!(:auth_source) { create(:ldap_auth_source) }
  let(:new_user_page) { Pages::NewUser.new }
  let(:mail) do
    ActionMailer::Base.deliveries.last
  end
  let(:mail_body) { mail.body.parts.first.body.to_s }
  let(:token) { mail_body.scan(/token=(.*)$/).first.first.strip }
  let(:user_menu) { Components::UserMenu.new }
  let(:required_custom_field) do
    create(:user_custom_field, :string, name: "Department", is_required: true)
  end

  before do
    allow(User).to receive(:current).and_return current_user
  end

  shared_examples_for "successful user creation" do |redirect_to_edit_page: true|
    it "creates the user" do
      new_user = User.order(Arel.sql("id DESC")).first

      expect(page).to have_current_path redirect_to_edit_page ? edit_user_path(new_user) : user_path(new_user)
    end

    it "sends out an activation email" do
      expect(mail_body).to include "activate your account"
      expect(token).not_to be_nil
    end
  end

  context "with internal authentication" do
    before do
      visit new_user_path

      new_user_page.fill_in! first_name: "bobfirst",
                             last_name: "boblast",
                             email: "bob@mail.com"
      perform_enqueued_jobs do
        new_user_page.submit!
        expect_flash(message: "Successful creation.")
      end
    end

    it_behaves_like "successful user creation"

    describe "activation" do
      before do
        allow(User).to receive(:current).and_call_original

        visit "/account/activate?token=#{token}"
      end

      it "shows the registration form" do
        expect(page).to have_text "Create a new account"
      end

      it "registers the user upon submission" do
        fill_in "user_password", with: "foobarbaz1"
        fill_in "user_password_confirmation", with: "foobarbaz1"

        click_button "Create"

        # landed on the 'my page'
        expect(page).to have_text "Welcome, your account has been activated. You are logged in now."
        user_menu.expect_user_shown "bobfirst boblast"
      end
    end
  end

  context "with external authentication" do
    before do
      visit new_user_page.path

      # Normally, the username field would appear on the page once
      # ldap_auth_source is set, but as we are acting without javascript, we
      # first create the user and then update it to set the username.
      #
      # We can't use the browser because it makes the spec flaky, and we were
      # unable to find why.
      new_user_page.fill_in! first_name: "bobfirst",
                             last_name: "boblast",
                             email: "bob@mail.com",
                             ldap_auth_source: auth_source.name

      perform_enqueued_jobs do
        new_user_page.submit!
        expect_flash(message: "Successful creation.")

        # Fill both "Username" fields on the edit user page: as they have the
        # same name, if only the first one is filled, then second one would
        # overwrite the value of the first one.
        page.all(:field, "Username", visible: :all).each do |field|
          field.fill_in with: "bob"
        end

        page.click_button "Save"
        expect_flash(message: "Successful update.")
      end
    end

    it_behaves_like "successful user creation"

    describe "activation" do
      before do
        # Ensure we clear any flashes
        visit "/logout"

        allow(User).to receive(:current).and_call_original

        visit "/account/activate?token=#{token}"
      end

      it "shows the login form prompting the user to login" do
        expect(page).to have_text "Please login as bob to activate your account."
      end

      it "registers the user upon submission" do
        user = User.find_by login: "bob"

        allow(User)
          .to(receive(:find_by_login))
          .with("bob")
          .and_return(user)

        allow(user).to receive(:ldap_auth_source).and_return(auth_source)

        allow(auth_source)
          .to(receive(:authenticate).with("bob", "dummy"))
          .and_return({ dn: "cn=bob,ou=users,dc=example,dc=com" })

        within "#content-body" do
          fill_in "password", with: "dummy" # accepted by DummyAuthSource
          click_button "Sign in", type: "submit"
        end

        # landed on the 'my page'
        expect(page).to have_text "Welcome to OpenProject, bobfirst boblast"
        expect(page).to have_current_path "/", ignore_query: true
        user_menu.expect_user_shown "bobfirst boblast"
      end
    end
  end

  context "as global user (with only create_user permission)" do
    shared_let(:global_create_user) { create(:user, global_permissions: %i[create_user]) }
    let(:current_user) { global_create_user }

    context "with internal authentication" do
      before do
        visit new_user_path

        new_user_page.fill_in! first_name: "bobfirst",
                               last_name: "boblast",
                               email: "bob@mail.com"

        perform_enqueued_jobs do
          new_user_page.submit!
          expect_flash(message: "Successful creation.")
        end
      end

      it_behaves_like "successful user creation", redirect_to_edit_page: false

      describe "activation" do
        before do
          allow(User).to receive(:current).and_call_original

          visit "/account/activate?token=#{token}"
        end

        it "shows the registration form" do
          expect(page).to have_text "Create a new account"
        end

        it "registers the user upon submission" do
          fill_in "user_password", with: "foobarbaz1"
          fill_in "user_password_confirmation", with: "foobarbaz1"

          click_button "Create"

          # landed on the 'my page'
          expect(page).to have_text "Welcome, your account has been activated. You are logged in now."
          user_menu.expect_user_shown "bobfirst boblast"
        end

        context "with required custom fields" do
          before do
            required_custom_field
          end

          it "I can activate a user with a custom field value including validation" do
            # The required custom field is created after the register form is shown.
            # This simulates a case where the user could remove the required custom field
            # from the form to be submitted in order to circumvent validation.
            expect(page).to have_no_field("user_custom_field_values_#{required_custom_field.id}")

            # Try to submit without filling the required custom field
            fill_in "user_password", with: "foobarbaz1"
            fill_in "user_password_confirmation", with: "foobarbaz1"

            click_button "Create"

            # Should stay on the form and show validation error
            expect(page).to have_text "Create a new account"
            expect(page).to have_css(".Banner--error", text: /Department can't be blank/)

            # Now fill the required custom field
            fill_in "user[custom_field_values][#{required_custom_field.id}]", with: "Engineering"

            # Refill password
            fill_in "user_password", with: "foobarbaz1"
            fill_in "user_password_confirmation", with: "foobarbaz1"

            click_button "Create"

            # Should succeed now
            expect(page).to have_text "Welcome, your account has been activated. You are logged in now."
            user_menu.expect_user_shown "bobfirst boblast"

            # Verify the custom field value was saved
            activated_user = User.find_by(mail: "bob@mail.com")
            expect(activated_user.typed_custom_value_for(required_custom_field)).to eq("Engineering")
          end
        end
      end
    end
  end

  context "as global user (with manage_user and create_user permission)" do
    shared_let(:global_create_user) { create(:user, global_permissions: %i[create_user manage_user]) }
    let(:current_user) { global_create_user }

    context "with internal authentication" do
      before do
        visit new_user_path

        new_user_page.fill_in! first_name: "bobfirst",
                               last_name: "boblast",
                               email: "bob@mail.com"

        perform_enqueued_jobs do
          new_user_page.submit!
          expect_flash(message: "Successful creation.")
        end
      end

      it_behaves_like "successful user creation", redirect_to_edit_page: true
    end
  end
end
