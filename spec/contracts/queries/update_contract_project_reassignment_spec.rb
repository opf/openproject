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

RSpec.describe Queries::UpdateContract do
  include_context "ModelContract shared context"

  let(:source_project) { create(:project) }
  let(:target_project) { create(:project) }
  let(:current_user) do
    create(:user, member_with_permissions: {
             source_project => %i[view_work_packages],
             target_project => %i[view_work_packages manage_public_queries]
           })
  end
  let!(:query) { create(:public_query, project: source_project, name: "Board list query") }

  subject(:contract) { described_class.new(query, current_user) }

  before do
    query.project = target_project
    query.name = "Renamed by attacker"
  end

  it_behaves_like "contract user is unauthorized"

  context "with manage_public_queries in both projects" do
    let(:current_user) do
      create(:user, member_with_permissions: {
               source_project => %i[view_work_packages manage_public_queries],
               target_project => %i[view_work_packages manage_public_queries]
             })
    end

    it_behaves_like "contract is valid"
  end
end
