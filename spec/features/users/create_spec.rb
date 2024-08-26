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

RSpec.describe "create users", :with_cuprite do
  shared_let(:admin) { create(:admin) }
  let(:current_user) { admin }
  let!(:auth_source) { create(:ldap_auth_source) }
  let(:new_user_page) { Pages::NewUser.new }
  let(:mail) do
    ActionMailer::Base.deliveries.last
  end
  let(:mail_body) { mail.body.parts.first.body.to_s }
  let(:token) { mail_body.scan(/token=(.*)$/).first.first.strip }

  before do
    allow(User).to receive(:current).and_return current_user
  end

  shared_examples_for "successful user creation" do |redirect_to_edit_page: true|
    it "creates the user" do
      expect(page).to have_css(".op-toast", text: "Successful creation.")

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
      end
    end

    it_behaves_like "successful user creation" do
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
          expect(page).to have_link "bobfirst boblast"
        end
      end
    end
  end

  context "with external authentication", :js do
    before do
      new_user_page.visit!

      new_user_page.fill_in! first_name: "bobfirst",
                             last_name: "boblast",
                             email: "bob@mail.com",
                             login: "bob",
                             ldap_auth_source: auth_source.name

      perform_enqueued_jobs do
        new_user_page.submit!
      end
    end

    after do
      # Clear session to avoid that the onboarding tour starts
      page.execute_script("window.sessionStorage.clear();")
    end

    it_behaves_like "successful user creation" do
      describe "activation", :js do
        before do
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

          fill_in "password", with: "dummy" # accepted by DummyAuthSource

          click_button "Sign in"

          expect(page).to have_text "OpenProject"
          expect(page).to have_current_path "/", ignore_query: true
          expect(page).to have_link "bobfirst boblast"
        end
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
        end
      end

      it_behaves_like "successful user creation", redirect_to_edit_page: false do
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
            expect(page).to have_link "bobfirst boblast"
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
        end
      end

      it_behaves_like "successful user creation", redirect_to_edit_page: true
    end
  end
end
