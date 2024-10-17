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

require "rails_helper"

RSpec.describe CustomFields::Hierarchy::InsertItemContract do
  subject { described_class.new }

  # rubocop:disable Rails/DeprecatedActiveModelErrorsMethods
  describe "#call" do
    let(:parent) { create(:hierarchy_item) }

    context "when all required fields are valid" do
      let(:params) { { parent:, label: "Valid Label" } }

      it "is valid" do
        result = subject.call(params)
        expect(result).to be_success
      end
    end

    context "when parent is not of type 'Item'" do
      let(:invalid_parent) { create(:custom_field) }
      let(:params) { { parent: invalid_parent, label: "Valid Label" } }

      it "is invalid" do
        result = subject.call(params)
        expect(result).to be_failure
        expect(result.errors.to_h).to include(parent: ["must be CustomField::Hierarchy::Item"])
      end
    end

    context "when label is not unique within the same hierarchy level" do
      before do
        create(:hierarchy_item, parent:, label: "Duplicate Label")
      end

      let(:params) { { parent:, label: "Duplicate Label" } }

      it "is invalid" do
        result = subject.call(params)
        expect(result).to be_failure
        expect(result.errors.to_h).to include(label: ["must be unique within the same hierarchy level"])
      end

      context "if locale is set to 'de'", skip: "Skipped until the german localization is available" do
        it "is invalid with localized validation errors" do
          I18n.with_locale(:de) do
            result = subject.call(params)
            expect(result).to be_failure
            expect(result.errors.to_h).to include(label: ["muss einzigartig innerhalb derselben Hierarchieebene sein"])
          end
        end
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
        expect(result.errors.to_h).to include(short: ["must be a string"])
      end
    end

    context "when inputs are valid" do
      it "creates a success result" do
        [
          { parent:, label: "A label", short: "A shorthand" },
          { parent:, label: "A label" }
        ].each { |params| expect(subject.call(params)).to be_success }
      end
    end

    context "when inputs are invalid" do
      it "creates a failure result" do
        [
          { parent:, label: "A label", short: "" },
          { parent:, label: "A label", short: nil },
          { parent:, label: "" },
          { parent:, label: nil },
          { parent: },
          { parent: nil },
          { parent: nil, label: "A label" },
          { parent: "parent", label: "A label" },
          { parent: 42, label: "A label" }
        ].each { |params| expect(subject.call(params)).to be_failure }
      end
    end
  end
  # rubocop:enable Rails/DeprecatedActiveModelErrorsMethods
end
