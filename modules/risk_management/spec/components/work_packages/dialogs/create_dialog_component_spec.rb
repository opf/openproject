# frozen_string_literal: true

require "spec_helper"
require_module_spec_helper

RSpec.describe WorkPackages::Dialogs::CreateDialogComponent, type: :component do
  let(:risk_type) { create(:type, name: "Risk") }
  let(:project) do
    create(:project, no_types: true).tap do |project|
      project.project_types.find_or_create_by!(type: risk_type) do |project_type|
        project_type.variant = risk_type.default_variant
      end
    end
  end
  let(:work_package) { build(:work_package, project:, type: risk_type) }

  before do
    configuration = instance_double(
      RiskManagement::Configuration,
      valid?: true,
      risk_type_id: risk_type.id,
      risk_type:
    )
    allow(RiskManagement::Configuration).to receive(:load).and_return(configuration)
  end

  it "uses the risk-specific dialog title" do
    component = described_class.new(work_package:, project:)

    expect(component.dialog_title).to eq("New risk")
  end
end
