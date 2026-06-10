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

RSpec.describe ModelContract do
  let(:user) { build_stubbed(:user) }
  let(:project) { create(:project) }

  describe "#valid?" do
    let(:contract_class) do
      Class.new(ModelContract) do
        attribute :name
      end
    end

    subject(:contract) { contract_class.new(project, user) }

    context "when validate_model? is true (the default)" do
      it "runs the model's own validations" do
        allow(project).to receive(:valid?).and_call_original

        contract.valid?

        expect(project).to have_received(:valid?).with(nil)
      end

      it "returns false when the model is invalid, even with no contract violations" do
        allow(project).to receive(:valid?) do
          project.errors.add(:base, :invalid)
          false
        end

        expect(contract.valid?).to be(false)
        expect(contract.errors.symbols_for(:base)).to include(:invalid)
      end

      it "preserves model errors instead of clearing them before contract checks" do
        allow(project).to receive(:valid?) do
          project.errors.add(:name, :too_short)
          false
        end

        contract.valid?

        expect(contract.errors.symbols_for(:name)).to include(:too_short)
      end
    end

    context "when validate_model? is false" do
      let(:contract_class) do
        Class.new(ModelContract) do
          attribute :name

          def validate_model? = false
        end
      end

      it "does not call model.valid?" do
        allow(project).to receive(:valid?).and_call_original

        contract.valid?

        expect(project).not_to have_received(:valid?)
      end

      it "clears prior errors on the model before contract validation" do
        project.errors.add(:base, :stale)

        contract.valid?

        expect(contract.errors.symbols_for(:base)).not_to include(:stale)
      end
    end
  end

  describe "readonly attribute enforcement" do
    let(:contract_class) do
      Class.new(ModelContract) do
        attribute :name # writable
        # description is intentionally not declared → readonly

        def validate_model? = false
      end
    end

    subject(:contract) { contract_class.new(project, user) }

    it "is valid when only writable attributes changed" do
      project.name = "Renamed"

      expect(contract).to be_valid
    end

    it "adds :error_readonly for each unwritable attribute the user changed" do
      project.description = "new description"

      expect(contract).not_to be_valid
      expect(contract.errors.symbols_for(:description)).to include(:error_readonly)
    end

    context "with an attribute_alias" do
      let(:contract_class) do
        Class.new(ModelContract) do
          attribute_alias :description, :external_description
          attribute :name

          def validate_model? = false
        end
      end

      it "reports the readonly error under the aliased (external) name" do
        project.description = "new description"

        contract.valid?

        expect(contract.errors.symbols_for(:external_description)).to include(:error_readonly)
        expect(contract.errors.symbols_for(:description)).not_to include(:error_readonly)
      end
    end
  end

  describe "#changed_by_user (private)" do
    let(:contract_class) do
      Class.new(ModelContract) do
        def validate_model? = false
      end
    end

    subject(:contract) { contract_class.new(project, user) }

    it "prefers model.changed_by_user when available" do
      project.define_singleton_method(:changed_by_user) { ["from_changed_by_user"] }
      allow(project).to receive_messages(
        changed_with_custom_fields: ["from_custom_fields"],
        changed: ["from_changed"]
      )

      expect(contract.send(:changed_by_user)).to eq(["from_changed_by_user"])
    end

    it "falls back to model.changed_with_custom_fields when changed_by_user is missing" do
      allow(project).to receive(:respond_to?).and_call_original
      allow(project).to receive(:respond_to?).with(:changed_by_user).and_return(false)
      allow(project).to receive_messages(
        changed_with_custom_fields: ["from_custom_fields"],
        changed: ["from_changed"]
      )

      expect(contract.send(:changed_by_user)).to eq(["from_custom_fields"])
    end

    it "falls back to model.changed when neither preferred method is available" do
      allow(project).to receive(:respond_to?).and_call_original
      allow(project).to receive(:respond_to?).with(:changed_by_user).and_return(false)
      allow(project).to receive(:respond_to?).with(:changed_with_custom_fields).and_return(false)
      allow(project).to receive(:changed).and_return(["from_changed"])

      expect(contract.send(:changed_by_user)).to eq(["from_changed"])
    end
  end

  describe ".stored_attribute" do
    # Project has a JSONB `settings` column with several store_attribute keys
    # (`sprint_sharing`, `deactivate_work_package_attachments`,
    # `enabled_internal_comments`, ...). We exercise the DSL against it rather
    # than building a throwaway AR model with its own table.
    let(:contract_class) do
      Class.new(ModelContract) do
        stored_attribute :sprint_sharing, store: :settings

        def validate_model? = false
      end
    end

    subject(:contract) { contract_class.new(project, user) }

    it "registers the virtual attribute as writable" do
      expect(contract_class.writable_attributes).to include("sprint_sharing")
    end

    it "registers the store column as a writable attribute (subject to the lambda)" do
      project.sprint_sharing = "share_subprojects"

      expect(contract.writable_attributes).to include("settings")
    end

    it "leaves the store column out of writable attributes when nothing in it changed" do
      expect(contract.writable_attributes).not_to include("settings")
    end

    it "is valid when only the registered stored attribute changed" do
      project.sprint_sharing = "share_subprojects"

      expect(contract).to be_valid
    end

    it "is invalid when an unregistered key in the same store changed" do
      project.deactivate_work_package_attachments = true

      expect(contract).not_to be_valid
      expect(contract.errors.symbols_for(:settings)).to include(:error_readonly)
    end

    it "declares the store column's writable lambda only once across multiple registrations" do
      multi_class = Class.new(ModelContract) do
        stored_attribute :sprint_sharing, store: :settings
        stored_attribute :deactivate_work_package_attachments, store: :settings

        def validate_model? = false
      end

      expect(multi_class.writable_attributes)
        .to contain_exactly("settings",
                            "settings_id",
                            "sprint_sharing",
                            "sprint_sharing_id",
                            "deactivate_work_package_attachments",
                            "deactivate_work_package_attachments_id")
    end

    context "with inheritance" do
      let(:subclass) do
        Class.new(contract_class) do
          stored_attribute :deactivate_work_package_attachments, store: :settings
        end
      end

      it "inherits parent stored_attribute declarations" do
        project.sprint_sharing = "share_subprojects"
        sub_contract = subclass.new(project, user)

        expect(sub_contract).to be_valid
      end

      it "extends the allowed keys list with subclass declarations" do
        project.sprint_sharing = "share_subprojects"
        project.deactivate_work_package_attachments = true
        sub_contract = subclass.new(project, user)

        expect(sub_contract).to be_valid
      end

      it "does not leak subclass declarations into the parent contract" do
        project.deactivate_work_package_attachments = true

        expect(contract).not_to be_valid
        expect(contract.errors.symbols_for(:settings)).to include(:error_readonly)
      end
    end
  end
end
