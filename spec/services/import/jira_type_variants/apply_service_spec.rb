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

RSpec.describe Import::JiraTypeVariants::ApplyService do
  shared_let(:user) { create(:admin) }
  shared_let(:jira_import) { create(:jira_import, author: user) }
  shared_let(:type) { create(:type, name: "Task") }
  shared_let(:project) { create(:project, no_types: true) }
  shared_let(:variant) { create(:project_owned_type_variant, type:, project:) }

  let(:variant_result) { ServiceResult.success(result: variant) }
  let(:switch_result) { ServiceResult.success(result: project) }
  let(:add_result) { ServiceResult.success(result: project) }

  let(:variant_service) { instance_double(Import::JiraTypeVariants::FindOrCreateService, call: variant_result) }
  let(:switch_service) { instance_double(Projects::Types::SwitchVariantService, call: switch_result) }
  let(:add_service) { instance_double(Projects::Types::AddService, call: add_result) }

  let(:service) { described_class.new(user:, jira_import:) }

  subject(:call) { service.call(type:, project:) }

  before do
    allow(Import::JiraTypeVariants::FindOrCreateService).to receive(:new).with(user:, jira_import:).and_return(variant_service)
    allow(Projects::Types::SwitchVariantService).to receive(:new).with(user:, model: project).and_return(switch_service)
    allow(Projects::Types::AddService).to receive(:new).with(user:, model: project).and_return(add_service)
  end

  context "when no variant is found or created" do
    let(:variant_result) { ServiceResult.failure }

    it "returns the failure without enabling anything" do
      expect(call).to be_failure
      expect(call).to eq(variant_result)

      expect(add_service).not_to have_received(:call)
      expect(switch_service).not_to have_received(:call)
    end
  end

  context "when the type is not enabled in the project" do
    it "adds the variant" do
      expect(call).to be_success
      expect(call.result).to eq(variant)

      expect(add_service).to have_received(:call).with(variant:)
      expect(switch_service).not_to have_received(:call)
    end

    context "when adding the variant fails" do
      let(:add_result) { ServiceResult.failure }

      it "returns the failure" do
        expect(call).to be_failure
        expect(call).to eq(add_result)

        expect(add_service).to have_received(:call)
        expect(switch_service).not_to have_received(:call)
      end
    end
  end

  context "when the type is enabled with its base variant" do
    let(:base_variant) { type.default_variant }

    before { create(:project_type, project:, type:) }

    it "switches to the variant" do
      expect(call).to be_success
      expect(call.result).to eq(variant)

      expect(switch_service).to have_received(:call).with(source: base_variant, target: variant)
      expect(add_service).not_to have_received(:call)
    end

    context "when switching the variant fails" do
      let(:switch_result) { ServiceResult.failure }

      it "returns the failure" do
        expect(call).to be_failure
        expect(call).to eq(switch_result)

        expect(switch_service).to have_received(:call)
        expect(add_service).not_to have_received(:call)
      end
    end
  end

  context "when the variant is already used" do
    before { create(:project_type, project:, type:, variant:) }

    it "just returns the variant again" do
      expect(call).to be_success
      expect(call.result).to eq(variant)

      expect(switch_service).not_to have_received(:call)
      expect(add_service).not_to have_received(:call)
    end
  end
end
