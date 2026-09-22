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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require "contracts/shared/model_contract_shared_context"

RSpec.shared_examples_for "an hourly rate contract" do
  include_context "ModelContract shared context"

  let(:project) { build_stubbed(:project) }
  let(:other_project) { build_stubbed(:project) }
  let(:current_user) { build_stubbed(:user) }
  let(:principal) { build_stubbed(:user) }
  let(:contract) { described_class.new(rate, current_user) }

  context "when the user may edit the hourly rates of the project" do
    before do
      mock_permissions_for(current_user) do |mock|
        mock.allow_in_project(:edit_hourly_rates, project:)
      end
    end

    it_behaves_like "contract is valid"
  end

  context "when the user may only edit their own hourly rate" do
    before do
      mock_permissions_for(current_user) do |mock|
        mock.allow_in_project(:edit_own_hourly_rate, project:)
      end
    end

    context "and the rate is their own" do
      let(:principal) { current_user }

      it_behaves_like "contract is valid"
    end

    context "and the rate belongs to somebody else" do
      it_behaves_like "contract user is unauthorized"
    end
  end

  context "when the user may edit hourly rates in another project only" do
    before do
      mock_permissions_for(current_user) do |mock|
        mock.allow_in_project(:edit_hourly_rates, project: other_project)
      end
    end

    it_behaves_like "contract user is unauthorized"
  end

  context "when the user holds no permission at all" do
    it_behaves_like "contract user is unauthorized"
  end
end
