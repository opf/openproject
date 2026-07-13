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
require_relative "shared_contract_examples"

RSpec.describe Users::UpdateContract do
  let!(:default_admin) { create(:admin) }

  it_behaves_like "user contract" do
    let(:current_user) { create(:admin) }
    let(:user) { build_stubbed(:user, attributes) }
    let(:contract) { described_class.new(user, current_user) }
    let(:attributes) do
      {
        firstname: user_firstname,
        lastname: user_lastname,
        login: user_login,
        mail: user_mail,
        password: nil,
        password_confirmation: nil
      }
    end

    context "with a system user" do
      let(:current_user) { create(:system) }
      let(:user) { create(:admin, attributes) }

      context "when admin flag is removed" do
        before do
          user.admin = false
        end

        it_behaves_like "contract is valid"

        context "when no admins left" do
          let(:default_admin) { nil }

          it_behaves_like "contract is invalid", base: :one_must_be_active
        end
      end

      context "when status is locked on an admin user" do
        before do
          user.status = :locked
        end

        it_behaves_like "contract is valid"

        context "when no admins left" do
          let(:default_admin) { nil }

          it_behaves_like "contract is invalid", base: :one_must_be_active
        end
      end

      context "when updated user authenticates through LDAP and basic attributes are changed" do
        let(:attributes) { super().merge(ldap_auth_source_id: create(:ldap_auth_source).id) }

        before do
          user.firstname = "Changed firstname"
          user.lastname = "Changed lastname"
          user.mail = "changed@example.com"
        end

        it_behaves_like "contract is valid"
      end

      context "when updated user authenticates through external provider and basic attributes are changed" do
        before do
          allow(user).to receive(:uses_external_authentication?).and_return(true)

          user.firstname = "Changed firstname"
          user.lastname = "Changed lastname"
          user.mail = "changed@example.com"
        end

        it_behaves_like "contract is valid"
      end
    end

    context "when user is an admin" do
      let(:current_user) { create(:admin) }

      describe "can update the email" do
        before do
          user.mail = "a.new@email.address"
        end

        it_behaves_like "contract is valid"
      end

      describe "can update the password" do
        before do
          user.password = "newpassword"
          user.password_confirmation = "newpassword"
        end

        it_behaves_like "contract is valid"
      end

      context "when updated user authenticates through LDAP and basic attributes are changed" do
        let(:attributes) { super().merge(ldap_auth_source_id: create(:ldap_auth_source).id) }

        before do
          user.firstname = "Changed firstname"
          user.lastname = "Changed lastname"
          user.mail = "changed@example.com"
        end

        it_behaves_like "contract is valid"
      end

      context "when updated user authenticates through external provider and basic attributes are changed" do
        before do
          allow(user).to receive(:uses_external_authentication?).and_return(true)

          user.firstname = "Changed firstname"
          user.lastname = "Changed lastname"
          user.mail = "changed@example.com"
        end

        it_behaves_like "contract is valid"
      end
    end

    context "when user with global manage_user permission" do
      let(:current_user) { create(:user, global_permissions: :manage_user) }

      describe "can lock the user" do
        before do
          user.status = Principal.statuses[:locked]
        end

        it_behaves_like "contract is valid"
      end

      describe "cannot update an administrator" do
        let(:user) { build_stubbed(:admin, attributes) }

        it_behaves_like "contract is invalid"
      end

      describe "cannot update the email" do
        before do
          user.mail = "a.new@email.address"
        end

        it_behaves_like "contract is invalid", mail: :error_readonly
      end

      context "when updated user authenticates through LDAP and basic attributes are changed" do
        let(:attributes) { super().merge(ldap_auth_source_id: create(:ldap_auth_source).id) }

        before do
          user.firstname = "Changed firstname"
          user.lastname = "Changed lastname"
        end

        it_behaves_like "contract is valid"
      end

      context "when updated user authenticates through external provider and basic attributes are changed" do
        before do
          allow(user).to receive(:uses_external_authentication?).and_return(true)

          user.firstname = "Changed firstname"
          user.lastname = "Changed lastname"
        end

        it_behaves_like "contract is valid"
      end
    end

    context "when updated user is current user" do
      # That scenario is the only that is not covered by the shared examples
      let(:current_user) { user }

      it_behaves_like "contract is valid"

      context "when setting status" do
        before do
          user.status = Principal.statuses[:locked]
        end

        it_behaves_like "contract is invalid", status: :error_readonly
      end

      describe "can update the email" do
        before do
          user.mail = "a.new@email.address"
        end

        it_behaves_like "contract is valid"
      end

      describe "when changing the password" do
        before do
          user.password = "newpassword123!"
          user.password_confirmation = "newpassword123!"
        end

        context "without current password" do
          it_behaves_like "contract is invalid", current_password: :invalid
        end

        context "with wrong current password" do
          before do
            user.current_password_input = "wrong-password"
          end

          it_behaves_like "contract is invalid", current_password: :invalid
        end

        context "with valid current password" do
          before do
            user.current_password_input = "adminADMIN!"
            allow(user).to receive(:check_password?).with("adminADMIN!").and_return(true)
          end

          it_behaves_like "contract is valid"
        end
      end

      context "when updated user authenticates through LDAP and basic attributes are changed" do
        let(:attributes) { super().merge(ldap_auth_source_id: create(:ldap_auth_source).id) }

        before do
          user.firstname = "Changed firstname"
          user.lastname = "Changed lastname"
          user.mail = "changed@example.com"
        end

        it_behaves_like "contract is invalid", firstname: :error_readonly, lastname: :error_readonly, mail: :error_readonly
      end

      context "when updated user authenticates through external provider and basic attributes are changed" do
        before do
          allow(user).to receive(:uses_external_authentication?).and_return(true)

          user.firstname = "Changed firstname"
          user.lastname = "Changed lastname"
          user.mail = "changed@example.com"
        end

        it_behaves_like "contract is invalid", firstname: :error_readonly, lastname: :error_readonly, mail: :error_readonly
      end
    end
  end
end
