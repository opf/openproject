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

RSpec.describe Import::JiraTypeVariants::CreateService, with_settings: { work_packages_identifier: "semantic" } do
  let(:user) { create(:admin) }
  let(:jira_import) { create(:jira_import, author: user) }
  let(:type) { create(:type, name: "Task") }
  let(:base_variant) { type.default_variant }
  let(:project) { create(:project, name: "Project XYZ", identifier: "XYZ") }
  let(:service) { described_class.new(user:, jira_import:) }

  let(:form) { build_stubbed(:form_configuration) }
  let(:workflow) { build_stubbed(:named_workflow) }
  let(:variant) { build_stubbed(:type_variant) }

  let(:form_result) { ServiceResult.success(result: form) }
  let(:workflow_result) { ServiceResult.success(result: workflow) }
  let(:variant_result) { ServiceResult.success(result: variant) }

  let(:form_service) { instance_double(FormConfigurations::CreateService, call: form_result) }
  let(:workflow_service) { instance_double(Workflows::CreateService, call: workflow_result) }
  let(:variant_service) { instance_double(WorkPackageTypes::CreateVariantService, call: variant_result) }

  let(:references) { Import::JiraOpenProjectReference.where(jira_import:) }

  subject(:call) { service.call(type:, project:) }

  before do
    allow(FormConfigurations::CreateService).to receive(:new).with(user:).and_return(form_service)
    allow(Workflows::CreateService).to receive(:new).with(user:).and_return(workflow_service)
    allow(WorkPackageTypes::CreateVariantService).to receive(:new).with(user:, type:).and_return(variant_service)
  end

  it "creates a project-owned type variant with own form and workflow" do
    expect(call).to be_success
    expect(call.result).to eq(variant)

    expect(form_service).to have_received(:call)
      .with(name: "Task (Jira XYZ)", copy_from_id: base_variant.form_configuration_id)
    expect(workflow_service).to have_received(:call)
      .with(name: "Task (Jira XYZ)", copy_from_id: base_variant.workflow_id)
    expect(variant_service).to have_received(:call)
      .with(
        variant_name: "Task",
        description: "Imported from Jira project Project XYZ",
        project_id: project.id,
        form_configuration_id: form.id,
        workflow_id: workflow.id
      )
  end

  it "stores references for the created artifacts" do
    expect { call }.to change(Import::JiraOpenProjectReference, :count).by(3)
    expect(references.pluck(:op_entity_class, :op_entity_id, :uses_existing)).to contain_exactly(
      ["FormConfiguration", form.id.to_s, false],
      ["Workflow", workflow.id.to_s, false],
      ["TypeVariant", variant.id.to_s, false]
    )
  end

  context "when creating the form fails" do
    let(:form_result) { ServiceResult.failure }

    it "returns the failure without creating any other resources" do
      expect(call).to be_failure
      expect(call).to eq(form_result)

      expect(form_service).to have_received(:call)
      expect(workflow_service).not_to have_received(:call)
      expect(variant_service).not_to have_received(:call)

      expect(references).to be_empty
    end
  end

  context "when creating the workflow fails" do
    let(:workflow_result) { ServiceResult.failure }

    it "returns the failure without creating any other resources" do
      expect(call).to be_failure
      expect(call).to eq(workflow_result)

      expect(form_service).to have_received(:call)
      expect(workflow_service).to have_received(:call)
      expect(variant_service).not_to have_received(:call)

      expect(references).to be_empty
    end
  end

  context "when creating the variant fails" do
    let(:variant_result) { ServiceResult.failure }

    it "returns the failure without creating any other resources" do
      expect(call).to be_failure
      expect(call).to eq(variant_result)

      expect(form_service).to have_received(:call)
      expect(workflow_service).to have_received(:call)
      expect(variant_service).to have_received(:call)

      expect(references).to be_empty
    end
  end
end
