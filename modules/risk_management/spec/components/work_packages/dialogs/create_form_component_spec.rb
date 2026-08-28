# frozen_string_literal: true

require "spec_helper"
require_module_spec_helper

RSpec.describe WorkPackages::Dialogs::CreateFormComponent, type: :component do
  subject(:render_component) { render_inline(described_class.new(work_package:, project:)) }

  let(:risk_type) { create(:type, name: "Risk", builtin_identifier: "risk") }
  let!(:default_status) { create(:status, is_default: true) }
  let!(:priority) { create(:default_priority) }
  let!(:category) { RiskManagement::RiskCategory.create!(name: "Strategic") }
  let(:project) do
    create(:project, no_types: true).tap do |project|
      project.project_types.create!(type: risk_type, variant: risk_type.default_variant)
    end
  end
  let(:work_package) { build(:work_package, project:, type: risk_type) }

  before { User.current = create(:admin) }

  it "renders the core risk fields without a type selector" do
    render_component

    expect(page).to have_text("Likelihood", count: 1)
    expect(page).to have_text("Impact", count: 1)
    expect(page).to have_text("Risk categories", count: 1)
    expect(page).to have_text("Risk response", count: 1)
    expect(page).to have_text("Risk owner", count: 1)
    expect(page).to have_text("Assignee", count: 1)
    expect(page).to have_no_text("Type")
  end
end
