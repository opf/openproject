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

module WorkPackageTypes
  RSpec.describe UpdateSettingsContract do
    let(:user) { create(:admin) }
    let(:model) { create(:type, name: "O-Negative") }
    let(:updated_attributes) { {} }

    subject(:contract) { described_class.new(model, user, options: {}) }

    before { model.attributes = updated_attributes }

    context "when the user isn't admin" do
      let(:user) { create(:user) }

      it "the contract is invalid" do
        expect(contract.validate).to be_falsey
      end

      it "adds and error to the contract" do
        contract.validate
        expect(contract.errors.details).to eq(base: [{ error: :error_unauthorized }])
      end
    end

    describe "name validations" do
      context "when name is blank" do
        let(:updated_attributes) { { name: "" } }

        it "the contract is invalid" do
          expect(contract.validate).to be_falsey
        end

        it "adds and error to the contract" do
          contract.validate
          expect(contract.errors.details[:name]).to eq([{ error: :blank }])
        end
      end

      context "when name is not unique (case insensitive)" do
        before { create(:type, name: "existing type") }

        let(:updated_attributes) { { name: "Existing Type" } }

        it "the contract is invalid" do
          expect(contract.validate).to be_falsey
        end

        it "adds and error to the contract" do
          contract.validate
          expect(contract.errors.details[:name]).to eq([{ error: :taken, value: updated_attributes[:name] }])
        end
      end

      context "when name is too long" do
        let(:updated_attributes) { { name: "A" * 300 } }

        it "the contract is invalid" do
          expect(contract.validate).to be_falsey
        end

        it "adds and error to the contract" do
          contract.validate
          expect(contract.errors.details[:name]).to eq([{ count: 255, error: :too_long }])
        end
      end

      context "when is_in_milestone or is_default aren't booleans" do
        let(:updated_attributes) { { is_default: nil, is_milestone: nil, is_in_roadmap: nil } }

        it "the contract is invalid" do
          expect(contract.validate).to be_falsey
        end

        it "adds and error to the contract" do
          contract.validate

          expect(contract.errors.details[:is_default]).to eq([{ error: :inclusion, value: nil }])
          expect(contract.errors.details[:is_milestone]).to eq([{ error: :inclusion, value: nil }])
          expect(contract.errors.details[:is_in_roadmap]).to eq([{ error: :inclusion, value: nil }])
        end
      end
    end

    describe "inherited core settings on a sub-type" do
      let(:parent) { create(:type) }
      let(:model) { create(:type, parent:) }

      context "when a core setting is changed" do
        let(:updated_attributes) do
          { color_id: create(:color).id, is_milestone: true, is_in_roadmap: false, is_default: true }
        end

        it "is invalid and marks each inherited setting as readonly" do
          expect(contract.validate).to be_falsey

          %i[color_id is_milestone is_in_roadmap is_default].each do |attribute|
            expect(contract.errors.details[attribute]).to eq([{ error: :error_readonly }])
          end
        end
      end

      context "when only the sub-type's own attributes change" do
        let(:updated_attributes) { { name: "Renamed variant", description: "A variant" } }

        it "is valid" do
          expect(contract.validate).to be_truthy
        end
      end
    end
  end
end
