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

RSpec.describe AI::TextTransformActions::SetAttributesService, type: :model do
  shared_let(:admin) { create(:admin) }
  shared_let(:type) { create(:type) }

  let(:instance) do
    described_class.new(user: admin, model:, contract_class: AI::TextTransformActions::CreateContract)
  end

  let(:base_params) { { label: "Translate", prompt: "Translate the text." } }

  context "with a new record" do
    let(:model) { AI::TextTransformAction.new }

    it "assigns the types for the specific scope, ignoring blank ids" do
      result = instance.call(base_params.merge(usage_scope: "specific_work_package_types", type_ids: ["", type.id.to_s]))

      expect(result).to be_success
      expect(model.types).to eq([type])
      expect(model).not_to be_persisted
    end

    it "drops the types and the template injection for the everywhere scope" do
      result = instance.call(base_params.merge(usage_scope: "everywhere", type_ids: [type.id.to_s],
                                               injects_type_template: true))

      expect(result).to be_success
      expect(model.types).to be_empty
      expect(model).not_to be_injects_type_template
    end

    it "keeps the template injection for work package scopes" do
      result = instance.call(base_params.merge(usage_scope: "all_work_package_types", injects_type_template: true))

      expect(result).to be_success
      expect(model).to be_injects_type_template
    end

    it "fails validation for the specific scope without types" do
      result = instance.call(base_params.merge(usage_scope: "specific_work_package_types", type_ids: [""]))

      expect(result).to be_failure
      expect(result.errors.symbols_for(:types)).to include(:blank)
    end
  end

  context "with a persisted record" do
    let(:model) { create(:ai_text_transform_action, :for_specific_types) }
    let(:instance) do
      described_class.new(user: admin, model:, contract_class: AI::TextTransformActions::UpdateContract)
    end

    it "keeps the types when type_ids are not given" do
      existing_types = model.types.to_a

      result = instance.call(label: "Renamed")

      expect(result).to be_success
      expect(model.types).to eq(existing_types)
    end

    it "clears the types when the scope changes away from specific" do
      result = instance.call(usage_scope: "all_work_package_types", type_ids: model.type_ids.map(&:to_s))

      expect(result).to be_success
      expect(model.types).to be_empty
    end
  end

  context "with a non-admin user" do
    let(:model) { AI::TextTransformAction.new }
    let(:instance) do
      described_class.new(user: create(:user), model:, contract_class: AI::TextTransformActions::CreateContract)
    end

    it "is unauthorized" do
      result = instance.call(base_params)

      expect(result).to be_failure
      expect(result.errors.symbols_for(:base)).to include(:error_unauthorized)
    end
  end
end
