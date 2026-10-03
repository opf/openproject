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
require_relative "shared_contract_examples"

RSpec.describe CustomFields::Hierarchy::InsertWeightedItemContract do
  subject(:result) { described_class.new.call(params) }

  let(:parent) { create(:hierarchy_item) }
  let(:valid_params) { { parent:, label: "Valid Label", weight: 0.1337 } }

  it_behaves_like "a hierarchy item insert contract"

  context "with a large weight" do
    let(:params) { valid_params.merge(weight: 1.47e12) }

    it { is_expected.to be_success }
  end

  context "with a weight a sibling already uses" do
    let(:params) { valid_params }

    before { create(:hierarchy_item, parent:, weight: 0.1337) }

    it("accepts it") { is_expected.to be_success }
  end

  context "without a weight" do
    let(:params) { valid_params.except(:weight) }

    it("rejects it") { expect(result.errors[:weight]).to include("is missing.") }
  end

  context "with a blank weight" do
    let(:params) { valid_params.merge(weight: "") }

    it("rejects it") { expect(result.errors[:weight]).to include("must be filled.") }
  end

  context "with a weight that is not a decimal" do
    let(:params) { valid_params.merge(weight: "pi") }

    it("rejects it") { expect(result.errors[:weight]).to include("must be a decimal.") }
  end
end
