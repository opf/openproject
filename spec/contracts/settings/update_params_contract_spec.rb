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

RSpec.describe Settings::UpdateParamsContract do
  include_context "ModelContract shared context"

  let(:current_user) { build_stubbed(:admin) }
  let(:params) { { journal_aggregation_time_minutes: "5" } }
  let(:contract) do
    described_class.new(nil, current_user, params:)
  end

  it_behaves_like "contract is valid for active admins and invalid for regular users"

  describe "journal_aggregation_time_minutes validation" do
    [0, 5, 120].each do |valid_value|
      context "with value #{valid_value}" do
        let(:params) { { journal_aggregation_time_minutes: valid_value.to_s } }

        it_behaves_like "contract is valid"
      end
    end

    [121, 9_999_999, -1].each do |invalid_value|
      context "with value #{invalid_value}" do
        let(:params) { { journal_aggregation_time_minutes: invalid_value.to_s } }

        it_behaves_like "contract is invalid", base: :journal_aggregation_time_minutes_is_out_of_bounds
      end
    end

    context "when not present in params" do
      let(:params) { {} }

      it_behaves_like "contract is valid"
    end
  end
end
