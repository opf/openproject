# frozen_string_literal: true

require "spec_helper"
require_module_spec_helper

RSpec.describe BasicData::RiskManagement::Seeder do
  include_context "with basic seed data"

  let(:seeder) { described_class.new }
  let!(:role) { create(:project_role) }

  before { basic_seeding }

  it "creates the built-in risk type, categories, statuses, and workflows" do
    seeder.seed!

    risk_type = Type.find_by!(builtin_identifier: "risk")
    expect(risk_type).to be_builtin
    expect(risk_type.name).to eq("Risk")
    expect(risk_type.default_variant.attribute_groups.flat_map(&:attributes)).to include(
      "risk_owner", "risk_likelihood", "risk_impact", "risk_exposure", "risk_category_ids", "risk_response"
    )
    expect(RiskManagement::RiskCategory.order(:position).pluck(:name)).to eq(described_class::RISK_CATEGORIES)
    expect(RiskManagement::RiskCategory.all).to all(be_active)

    statuses = Status.where(name: described_class::RISK_STATUSES.keys).index_by(&:name)
    expect(statuses.transform_values(&:is_closed)).to eq(described_class::RISK_STATUSES)
    expect(statuses.transform_values { |status| status.color.name }).to eq(described_class::RISK_STATUS_COLORS)

    expected = described_class::RISK_WORKFLOW.flat_map do |old_name, new_names|
      new_names.map { |new_name| [statuses.fetch(old_name).id, statuses.fetch(new_name).id] }
    end
    expect(Workflow.where(type_variant: risk_type.default_variant, role:).pluck(:old_status_id, :new_status_id))
      .to match_array(expected)
  end

  it "is idempotent" do
    seeder.seed!

    expect { described_class.new.seed! }
      .to not_change(Type.where(builtin_identifier: "risk"), :count)
      .and not_change(RiskManagement::RiskCategory, :count)
      .and not_change(Status, :count)
      .and not_change(Workflow, :count)
  end
end
