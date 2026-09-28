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

RSpec.describe CustomFields::Hierarchy::InsertHierarchyItemContract do
  subject(:result) { described_class.new.call(params) }

  let(:parent) { create(:hierarchy_item) }
  let(:valid_params) { { parent:, label: "Valid Label", short: nil } }

  context "with a label and no short" do
    let(:params) { valid_params }

    it { is_expected.to be_success }
  end

  context "with a short" do
    let(:params) { valid_params.merge(short: "Valid Short") }

    it { is_expected.to be_success }
  end

  context "with a parent below the root" do
    let(:params) { valid_params.merge(parent: create(:hierarchy_item, parent:)) }

    it("accepts it, since hierarchies nest") { is_expected.to be_success }
  end

  context "without a parent" do
    let(:params) { valid_params.merge(parent: nil) }

    it("rejects it") { expect(result.errors[:parent]).to include("must be filled.") }
  end

  context "with a parent that is not an item" do
    let(:params) { valid_params.merge(parent: create(:custom_field)) }

    it("rejects it") { expect(result.errors[:parent]).to include("must be CustomField::Hierarchy::Item.") }
  end

  context "with an unsaved parent" do
    let(:params) { valid_params.merge(parent: build(:hierarchy_item)) }

    it("rejects it") { expect(result.errors[:parent]).to include("must exist") }
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
    let(:params) { valid_params.merge(label: "Duplicate Label") }

    before { create(:hierarchy_item, parent:, label: "Duplicate Label") }

    it("rejects it") { expect(result.errors[:label]).to include("must be unique within the same hierarchy level.") }

    context "in another locale" do
      let(:mordor) { "agh burzum-ishi krimpatul" }

      before do
        I18n.config.enforce_available_locales = false
        I18n.backend.store_translations(:mo, { op_dry_validation: { errors: { rules: { label: { not_unique: mordor } } } } })
      end

      after { I18n.config.enforce_available_locales = true }

      it("rejects it in that locale") { I18n.with_locale(:mo) { expect(result.errors[:label]).to include(mordor) } }
    end
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
    let(:params) { valid_params.merge(short: "Repeated Short") }

    before { create(:hierarchy_item, parent:, label: "Unique Label", short: "Repeated Short") }

    it("rejects it") { expect(result.errors[:short]).to include("must be unique within the same hierarchy level.") }
  end
end
