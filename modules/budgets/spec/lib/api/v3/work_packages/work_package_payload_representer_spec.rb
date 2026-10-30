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

RSpec.describe API::V3::WorkPackages::WorkPackagePayloadRepresenter do
  include API::V3::Utilities::PathHelper

  let(:user) { build_stubbed(:user) }
  let(:budget) { build_stubbed(:budget) }
  let(:work_package) { build_stubbed(:work_package, budget:) }
  let(:representer) { described_class.create(work_package, current_user: user) }

  subject(:generated) { representer.to_json }

  before do
    mock_permissions_for(user, &:allow_everything)
  end

  describe "budget link" do
    context "without a budget assigned" do
      let(:budget) { nil }

      it "renders an empty budget href" do
        expect(subject)
          .to be_json_eql(nil.to_json)
                .at_path("_links/budget/href")
      end
    end

    context "with a budget assigned" do
      it "links the budget" do
        expect(subject)
          .to be_json_eql(api_v3_paths.budget(budget.id).to_json)
                .at_path("_links/budget/href")
      end
    end

    context "without necessary permissions" do
      before do
        mock_permissions_for(user, &:forbid_everything)
      end

      it "has no budget link" do
        expect(subject)
          .not_to have_json_path("_links/budget")
      end
    end
  end
end
