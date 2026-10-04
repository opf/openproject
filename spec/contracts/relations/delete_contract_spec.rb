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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require "contracts/shared/model_contract_shared_context"

RSpec.describe Relations::DeleteContract do
  include_context "ModelContract shared context"

  shared_let(:from_project) { create(:project) }
  shared_let(:to_project) { create(:project) }
  shared_let(:from_work_package) { create(:work_package, project: from_project) }
  shared_let(:to_work_package) { create(:work_package, project: to_project) }
  shared_let(:relation) { create(:relation, from: from_work_package, to: to_work_package) }

  let(:contract) { described_class.new(relation, current_user) }

  context "when user has permission to manage relations for both work packages" do
    let(:current_user) do
      create(:user,
             member_with_permissions: {
               from_project => %i[manage_work_package_relations],
               to_project => %i[manage_work_package_relations]
             })
    end

    it_behaves_like "contract is valid"
  end

  context "when user has permission for 'from' work package but not 'to' work package" do
    let(:current_user) do
      create(:user,
             member_with_permissions: {
               from_project => %i[manage_work_package_relations]
             })
    end

    it_behaves_like "contract is invalid", base: :error_not_deletable
  end

  context "when user has permission for 'to' work package but not 'from' work package" do
    let(:current_user) do
      create(:user,
             member_with_permissions: {
               to_project => %i[manage_work_package_relations]
             })
    end

    it_behaves_like "contract is invalid", base: :error_not_deletable
  end

  context "when user has no permissions for either work package" do
    let(:current_user) { create(:user) }

    it_behaves_like "contract is invalid", base: :error_not_deletable
  end

  context "when user is an admin" do
    let(:current_user) { create(:admin) }

    it_behaves_like "contract is valid"
  end

  include_examples "contract reuses the model errors" do
    let(:current_user) { create(:admin) }
  end
end
