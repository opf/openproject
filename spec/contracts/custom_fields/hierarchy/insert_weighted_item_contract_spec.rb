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

RSpec.describe CustomFields::Hierarchy::InsertWeightedItemContract do
  subject { described_class.new }

  # rubocop:disable Rails/DeprecatedActiveModelErrorsMethods
  describe "#call" do
    let(:parent) { create(:hierarchy_item) }

    context "when all required fields are valid" do
      let(:params) { { parent:, label: "Valid Label", weight: 0.1337 } }

      it "is valid" do
        result = subject.call(params)
        expect(result).to be_success
      end
    end

    context "when inputs are empty" do
      let(:params) { { parent:, label: "", weight: "" } }

      it "is invalid" do
        result = subject.call(params)
        expect(result).to be_failure
        expect(result.errors.to_h).to include(label: ["must be filled."])
        expect(result.errors.to_h).to include(weight: ["must be filled."])
      end
    end

    context "when inputs are missing" do
      let(:params) { { parent: } }

      it "is invalid" do
        result = subject.call(params)
        expect(result).to be_failure
        expect(result.errors.to_h).to include(label: ["is missing."])
        expect(result.errors.to_h).to include(weight: ["is missing."])
      end
    end

    context "when parent is not of type 'Item'" do
      let(:invalid_parent) { create(:custom_field) }
      let(:params) { { parent: invalid_parent, label: "Valid Label", weight: 0.1337 } }

      it "is invalid" do
        result = subject.call(params)
        expect(result).to be_failure
        expect(result.errors.to_h).to include(parent: ["must be CustomField::Hierarchy::Item."])
      end
    end

    context "when label is not unique within the same hierarchy level" do
      let(:params) { { parent:, label: "Duplicate Label", weight: 0.1337 } }

      before { create(:hierarchy_item, parent:, label: "Duplicate Label", weight: 0.1337) }

      it "is invalid" do
        result = subject.call(params)
        expect(result).to be_failure
        expect(result.errors.to_h).to include(label: ["must be unique within the same hierarchy level."])
      end

      context "if another locale is set" do
        let(:mordor) { "agh burzum-ishi krimpatul" }

        before do
          I18n.config.enforce_available_locales = false
          I18n.backend.store_translations(
            :mo,
            { op_dry_validation: {
              errors: { rules: { label: { not_unique: mordor } } }
            } }
          )
        end

        after do
          I18n.config.enforce_available_locales = true
        end

        it "is invalid with localized validation errors" do
          I18n.with_locale(:mo) do
            result = subject.call(params)
            expect(result).to be_failure
            expect(result.errors.to_h).to include(label: [mordor])
          end
        end
      end
    end

    context "when weight is not a decimal value" do
      let(:params) { { parent:, label: "Valid Label", weight: "pi" } }

      it "is invalid with localized validation errors" do
        result = subject.call(params)
        expect(result).to be_failure
        expect(result.errors.to_h).to include(weight: ["must be a decimal."])
      end
    end

    context "when inputs are valid" do
      it "creates a success result" do
        [
          { parent:, label: "A label", weight: 0.1337 },
          { parent:, label: "Another label", weight: 1.47e12 }
        ].each { |params| expect(subject.call(params)).to be_success }
      end
    end

    context "when inputs are invalid" do
      it "creates a failure result" do
        [
          { parent:, label: "A label", weight: "" },
          { parent:, label: "A label", weight: nil },
          { parent:, label: "", weight: 1.47e12 },
          { parent:, label: nil, weight: 1.47e12 },
          { parent: },
          { parent: nil },
          { parent: nil, label: "A label", weight: 1.47e12 },
          { parent: "parent", label: "A label", weight: 1.47e12 },
          { parent: 42, label: "A label", weight: 1.47e12 }
        ].each { |params| expect(subject.call(params)).to be_failure }
      end
    end
  end
  # rubocop:enable Rails/DeprecatedActiveModelErrorsMethods
end
