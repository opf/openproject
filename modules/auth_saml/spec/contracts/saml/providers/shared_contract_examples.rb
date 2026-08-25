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

require "contracts/shared/model_contract_shared_context"

RSpec.shared_context "as saml provider contract" do
  include_context "ModelContract shared context"

  let(:contract) { described_class.new provider, current_user }

  context "when admin" do
    let(:current_user) { build_stubbed(:admin) }

    it_behaves_like "contract is valid"
  end

  context "when non-admin" do
    let(:current_user) { build_stubbed(:user) }

    it_behaves_like "contract is invalid", base: :error_unauthorized
  end

  describe "allowed_clock_drift" do
    let(:current_user) { build_stubbed(:admin) }

    before do
      provider.allowed_clock_drift = value
    end

    context "with a positive number of seconds" do
      let(:value) { 5 }

      it_behaves_like "contract is valid"
    end

    context "with a fraction of a second" do
      let(:value) { 0.5 }

      it_behaves_like "contract is valid"
    end

    context "with a negative number of seconds" do
      let(:value) { -1 }

      it_behaves_like "contract is invalid", allowed_clock_drift: :greater_than_or_equal_to
    end

    context "with a negative fraction of a second" do
      let(:value) { -0.5 }

      it_behaves_like "contract is invalid", allowed_clock_drift: :greater_than_or_equal_to
    end

    context "with a value exceeding the maximum" do
      let(:value) { Saml::Providers::BaseContract::MAX_ALLOWED_CLOCK_DRIFT + 0.5 }

      it_behaves_like "contract is invalid", allowed_clock_drift: :less_than_or_equal_to
    end
  end
end
