# frozen_string_literal: true

require "spec_helper"
require_module_spec_helper

RSpec.describe DemoData::RiskManagement::RisksSeeder do
  include_context "with basic seed data"

  let!(:admin) { create(:admin) }
  let!(:priority) { create(:default_priority) }
  let!(:project) { create(:project, enabled_module_names: ["work_package_tracking"]) }

  before do
    basic_seeding
    BasicData::RiskManagement::Seeder.new.seed!
  end

  it "creates twelve risks with core risk attributes and a plan" do
    expect { described_class.new.seed! }.to change(WorkPackage, :count).by(12)

    risk_type = Type.find_by!(builtin_identifier: "risk")
    risks = WorkPackage.where(project:, type: risk_type)
    expect(risks.where.not(risk_owner_id: nil).count).to eq(10)
    expect(risks.where(risk_owner_id: nil).count).to eq(2)
    expect(risks.where.not(risk_likelihood: nil).where.not(risk_impact: nil).count).to eq(12)
    expect(risks.where.not(risk_response: [nil, ""]).count).to eq(11)
    expect(risks).to all(satisfy { |risk| risk.risk_category_ids.any? })
    expect(project.reload.enabled_module_names).to include("risk_log")
    expect(RiskManagement::Plan.find_by(project:)&.body).to include("Purpose and objectives")
  end

  it "does not create duplicate example risks or plans" do
    described_class.new.seed!

    expect { described_class.new.seed! }
      .to not_change(WorkPackage, :count)
      .and not_change(RiskManagement::Plan, :count)
  end
end
