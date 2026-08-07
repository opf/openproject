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
  RSpec.describe CreateContract do
    let(:user) { create(:admin) }
    let(:base_attributes) do
      { name: "O-Negative", description: nil, is_milestone: true, is_default: false, is_in_roadmap: true }
    end
    let(:attributes) { base_attributes }
    let(:model) { Type.new(attributes) }

    subject(:contract) { described_class.new(model, user, options: {}) }

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
        let(:attributes) { base_attributes.merge(name: "") }

        it "the contract is invalid" do
          expect(contract.validate).to be_falsey
        end

        it "adds and error to the contract" do
          contract.validate
          expect(contract.errors.details[:name]).to eq([{ error: :blank }])
        end
      end

      context "when name is not unique (case insensitive)" do
        before { create(:type, name: "o-negative") }

        it "the contract is invalid" do
          expect(contract.validate).to be_falsey
        end

        it "adds and error to the contract" do
          contract.validate
          expect(contract.errors.details[:name]).to eq([{ error: :taken, value: attributes[:name] }])
        end
      end

      context "when name is too long" do
        let(:attributes) { base_attributes.merge(name: "A" * 300) }

        it "the contract is invalid" do
          expect(contract.validate).to be_falsey
        end

        it "adds and error to the contract" do
          contract.validate
          expect(contract.errors.details[:name]).to eq([{ count: 255, error: :too_long }])
        end
      end

      context "when is_in_milestone or is_default aren't booleans" do
        let(:attributes) { base_attributes.merge(is_default: nil, is_milestone: nil, is_in_roadmap: nil) }

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

    describe "inherited core settings on a variant" do
      let(:parent) { create(:type) }

      context "when core settings are provided" do
        let(:attributes) do
          { name: "Variant",
            parent_id: parent.id,
            color_id: create(:color).id,
            is_milestone: true,
            is_in_roadmap: false,
            is_default: true }
        end

        it "is invalid" do
          expect(contract.validate).to be_falsey
        end

        it "marks each inherited setting as readonly" do
          contract.validate

          %i[color_id is_milestone is_in_roadmap is_default].each do |attribute|
            expect(contract.errors.details[attribute]).to eq([{ error: :error_readonly }])
          end
        end
      end

      context "when only the variant's own attributes are set" do
        let(:attributes) { { name: "Variant", parent_id: parent.id } }

        it "is valid" do
          expect(contract.validate).to be_truthy
        end
      end
    end

    describe "as a project administrator" do
      shared_let(:owner) { create(:project) }
      shared_let(:root) { create(:type) }
      shared_let(:project_admin) do
        create(:user, member_with_permissions: { owner => %i[manage_project_variants] })
      end

      let(:user) { project_admin }

      context "with a variant its own project owns" do
        let(:attributes) { { name: "Ours", parent_id: root.id, project: owner } }

        it "is valid" do
          expect(contract.validate).to be_truthy
        end
      end

      context "with a variant another project owns" do
        let(:attributes) { { name: "Theirs", parent_id: root.id, project: create(:project) } }

        it "is invalid" do
          expect(contract.validate).to be_falsey
        end
      end

      # Global types stay an instance-administrator concern.
      context "with a global variant" do
        let(:attributes) { { name: "Global", parent_id: root.id } }

        it "is invalid" do
          expect(contract.validate).to be_falsey
        end
      end

      context "without the permission" do
        let(:user) { create(:user, member_with_permissions: { owner => %i[view_project] }) }
        let(:attributes) { { name: "Ours", parent_id: root.id, project: owner } }

        it "is invalid" do
          expect(contract.validate).to be_falsey
        end
      end
    end
  end
end
