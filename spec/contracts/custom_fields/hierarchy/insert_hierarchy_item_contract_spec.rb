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
  subject { described_class.new }

  # rubocop:disable Rails/DeprecatedActiveModelErrorsMethods
  describe "#call" do
    let(:parent) { create(:hierarchy_item) }

    context "when all required fields are valid" do
      let(:params) { { parent:, label: "Valid Label", short: nil } }

      it "is valid" do
        result = subject.call(params)
        expect(result).to be_success
      end
    end

    context "when parent is not of type 'Item'" do
      let(:invalid_parent) { create(:custom_field) }
      let(:params) { { parent: invalid_parent, label: "Valid Label", short: nil } }

      it "is invalid" do
        result = subject.call(params)
        expect(result).to be_failure
        expect(result.errors.to_h).to include(parent: ["must be CustomField::Hierarchy::Item."])
      end
    end

    context "when label is not unique within the same hierarchy level" do
      before do
        create(:hierarchy_item, parent:, label: "Duplicate Label")
      end

      let(:params) { { parent:, label: "Duplicate Label", short: nil } }

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

    context "when short is not unique in the same hierarchy level" do
      let(:params) { { parent:, label: "Valid Label", short: "Repeated Short" } }

      before { create(:hierarchy_item, parent:, label: "Unique Label", short: "Repeated Short") }

      it "is invalid with localized validation errors" do
        result = subject.call(params)
        expect(result).to be_failure
        expect(result.errors.to_h).to include(short: ["must be unique within the same hierarchy level."])
      end
    end

    context "when short is set and is a string" do
      let(:params) { { parent:, label: "Valid Label", short: "Valid Short" } }

      it "is valid" do
        result = subject.call(params)
        expect(result).to be_success
      end
    end

    context "when short is set and is not a string" do
      let(:params) { { parent:, label: "Valid Label", short: 123 } }

      it "is invalid" do
        result = subject.call(params)
        expect(result).to be_failure
        expect(result.errors.to_h).to include(short: ["must be a string."])
      end
    end

    context "when inputs are valid" do
      it "creates a success result" do
        [
          { parent:, label: "A label", short: "A shorthand" },
          { parent:, label: "A label", short: nil }
        ].each { |params| expect(subject.call(params)).to be_success }
      end
    end

    context "when inputs are invalid" do
      it "creates a failure result" do
        [
          { parent: },
          { parent:, label: "A label" },
          { parent:, short: "AL" },
          { parent: nil, label: "A label", short: nil },
          { parent: 42, label: "A label", short: nil },
          { parent:, label: nil, short: nil },
          { parent:, label: 42, short: nil },
          { parent:, label: "A label", short: 42 }
        ].each { |params| expect(subject.call(params)).to be_failure }
      end
    end
  end
  # rubocop:enable Rails/DeprecatedActiveModelErrorsMethods
end
