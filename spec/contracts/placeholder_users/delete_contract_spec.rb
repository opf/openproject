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

RSpec.describe PlaceholderUsers::DeleteContract do
  include_context "ModelContract shared context"

  let(:placeholder_user) { create(:placeholder_user) }
  let(:role) { create(:existing_project_role, permissions: [:manage_members]) }
  let(:shared_project) { create(:project, members: { placeholder_user => role, current_user => role }) }
  let(:not_shared_project) { create(:project, members: { placeholder_user => role }) }
  let(:contract) { described_class.new(placeholder_user, current_user) }

  it_behaves_like "contract is valid for active admins and invalid for regular users"

  context "when user with global permission to manage_placeholders" do
    let(:current_user) { create(:user, global_permissions: %i[manage_placeholder_user]) }

    before do
      shared_project
    end

    context "when user is allowed to manage members in all projects of the placeholder user" do
      it_behaves_like "contract is valid"
    end

    context "when user is not allowed to manage members in all projects of the placeholder user" do
      before do
        not_shared_project
      end

      it_behaves_like "contract user is unauthorized"
    end
  end

  include_examples "contract reuses the model errors" do
    let(:current_user) { build_stubbed(:admin) }
  end
end
