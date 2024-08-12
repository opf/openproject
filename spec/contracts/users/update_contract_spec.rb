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
    end

    context "when global user" do
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
    end
  end
end
