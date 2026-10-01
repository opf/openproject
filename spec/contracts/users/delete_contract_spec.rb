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
require "contracts/shared/model_contract_shared_context"

RSpec.describe Users::DeleteContract do
  include_context "ModelContract shared context"

  let(:user) { create(:user) }
  let(:contract) { described_class.new(user, current_user) }

  context "when self deletion is allowed", with_settings: { users_deletable_by_self: true } do
    context "when user is the current user" do
      let(:current_user) { user }

      it_behaves_like "contract is valid"
    end

    context "when user is not the current user" do
      let(:current_user) { create(:user) }

      it_behaves_like "contract is invalid"
    end

    context "when the only admin tries to delete itself" do
      let(:user) { create(:admin) }
      let(:current_user) { user }

      it_behaves_like "contract is invalid"
    end

    context "when the last active admin tries to delete itself" do
      let!(:other_admin) { create(:admin, status: :locked) }
      let(:user) { create(:admin) }
      let(:current_user) { user }

      it_behaves_like "contract is invalid"
    end

    context "when one of many admins tries to delete itself" do
      let!(:other_admin) { create(:admin) }
      let(:user) { create(:admin) }
      let(:current_user) { user }

      it_behaves_like "contract is valid"
    end
  end

  context "when self deletion is not allowed", with_settings: { users_deletable_by_self: false } do
    context "when user is the current user" do
      let(:current_user) { user }

      it_behaves_like "contract is invalid"
    end
  end

  context "when deletion by admins is allowed", with_settings: { users_deletable_by_admins: true } do
    context "when current user is an admin" do
      let(:current_user) { create(:admin) }

      it_behaves_like "contract is valid"

      context "and deleted user is also an admin" do
        let(:user) { create(:admin) }

        it_behaves_like "contract is valid"
      end
    end

    context "when current user is not an admin" do
      let(:current_user) { create(:user, global_permissions: [:manage_user]) }

      it_behaves_like "contract is invalid"
    end

    context "when the only admin tries to delete itself" do
      let(:user) { create(:admin) }
      let(:current_user) { user }

      it_behaves_like "contract is invalid"
    end
  end

  include_examples "contract reuses the model errors" do
    let(:current_user) { build_stubbed(:admin) }
  end
end
