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

RSpec.describe CustomFields::Hierarchy::UpdateHierarchyItemContract do
  subject(:result) { described_class.new.call(params) }

  let!(:vader) { create(:hierarchy_item) }
  let!(:luke) { create(:hierarchy_item, label: "luke", short: "ls", parent: vader) }
  let!(:leia) { create(:hierarchy_item, label: "leia", short: "lo", parent: vader) }
  let(:valid_params) { { item: luke, label: "Luke Skywalker", short: "LS" } }

  context "with a new label and short" do
    let(:params) { valid_params }

    it { is_expected.to be_success }
  end

  context "with its own label and short kept" do
    let(:params) { valid_params.merge(label: "luke", short: "ls") }

    it { is_expected.to be_success }
  end

  context "with the short cleared" do
    let(:params) { valid_params.merge(short: nil) }

    it { is_expected.to be_success }
  end

  context "with an item two levels below the root" do
    let(:params) { valid_params.merge(item: create(:hierarchy_item, label: "ben", parent: leia)) }

    it("accepts it, since hierarchies nest") { is_expected.to be_success }
  end

  context "without an item" do
    let(:params) { valid_params.merge(item: nil) }

    it("rejects it") { expect(result.errors[:item]).to include("must be filled.") }
  end

  context "with the root item" do
    let(:params) { valid_params.merge(item: vader) }

    it("rejects it") { expect(result.errors[:item]).to include("cannot be a root item.") }
  end

  context "with an item that is not an item" do
    let(:params) { valid_params.merge(item: create(:custom_field)) }

    it("rejects it") { expect(result.errors[:item]).to include("must be CustomField::Hierarchy::Item.") }
  end

  context "with an unsaved item" do
    let(:params) { valid_params.merge(item: build(:hierarchy_item, parent: vader)) }

    it("rejects it") { expect(result.errors[:item]).to include("must be an already existing item.") }
  end

  context "without a label" do
    let(:params) { valid_params.except(:label) }

    it("rejects it") { expect(result.errors[:label]).to include("is missing.") }
  end

  context "with a blank label" do
    let(:params) { valid_params.merge(label: nil) }

    it("rejects it") { expect(result.errors[:label]).to include("must be filled.") }
  end

  context "with a label that is not a string" do
    let(:params) { valid_params.merge(label: 42) }

    it("rejects it") { expect(result.errors[:label]).to include("must be a string.") }
  end

  context "with a label a sibling already uses" do
    let(:params) { valid_params.merge(label: "leia") }

    it("rejects it") { expect(result.errors[:label]).to include("must be unique within the same hierarchy level.") }
  end

  context "without a short key" do
    let(:params) { valid_params.except(:short) }

    it("rejects it") { expect(result.errors[:short]).to include("is missing.") }
  end

  context "with a short that is not a string" do
    let(:params) { valid_params.merge(short: 42) }

    it("rejects it") { expect(result.errors[:short]).to include("must be a string.") }
  end

  context "with a short a sibling already uses" do
    let(:params) { valid_params.merge(short: "lo") }

    it("rejects it") { expect(result.errors[:short]).to include("must be unique within the same hierarchy level.") }
  end
end
