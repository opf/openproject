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

RSpec.shared_examples_for "group contract" do
  include_context "ModelContract shared context"

  let(:group_name) { "The group" }
  let(:group_users_user_ids) { [42, 43] }
  let(:group_users) do
    group_users_user_ids.map { |id| build_stubbed(:group_user, user_id: id) }
  end

  shared_context "with real group users" do
    # make sure users actually exist (not just stubbed) in this case
    # so GroupUser validations checking for the existence of group and user don't fail
    before do
      group_users_user_ids.each do |id|
        create(:user, id:)
      end
    end
  end

  it_behaves_like "contract is valid for active admins and invalid for regular users" do
    include_context "with real group users"
  end

  describe "validations" do
    let(:current_user) { build_stubbed(:admin) }

    context "name" do
      context "is valid" do
        include_context "with real group users"

        it_behaves_like "contract is valid"
      end

      context "is too long" do
        let(:group_name) { "X" * 257 }

        it_behaves_like "contract is invalid", name: :too_long
      end

      context "is not empty" do
        let(:group_name) { "" }

        it_behaves_like "contract is invalid", name: :blank
      end

      context "is unique" do
        before do
          Group.create(name: group_name)
        end

        it_behaves_like "contract is invalid", name: :taken
      end
    end

    context "groups_users" do
      let(:group_users) do
        [build_stubbed(:group_user, user_id: 1),
         build_stubbed(:group_user, user_id: 1)]
      end

      it_behaves_like "contract is invalid", group_users: :taken
    end
  end

  include_examples "contract reuses the model errors" do
    let(:current_user) { build_stubbed(:user) }
  end
end
