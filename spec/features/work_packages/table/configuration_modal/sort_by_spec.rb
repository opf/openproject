# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Work Package table configuration modal sort-by spec", :js do
  let(:user) { create(:admin) }
  let(:project) { create(:project) }
  let!(:work_package) { create(:work_package, project:) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:modal) { Components::WorkPackages::TableConfigurationModal.new }

  before do
    login_as(user)
    wp_table.visit!
    wp_table.expect_work_package_listed(work_package)
  end

  it "does not offer internal, non-displayable columns as sort options (COMMS-930)" do
    modal.open_and_switch_to("Sort by")

    option_texts = page.all("#modal-sorting select.form--select option").map(&:text)

    expect(option_texts).not_to include("Autocomplete")
    expect(option_texts).to include("Status")
  end
end
