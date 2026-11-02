# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::TestRuns::CompleteDialogComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:test_run) { create(:tm_test_run, :in_progress, project:, name: "Sprint smoke") }

  subject(:rendered_component) do
    with_request_url "/projects/#{project.id}/test_management/test_runs/#{test_run.id}" do
      render_inline(described_class.new(test_run:, project:))
    end
  end

  it "renders the complete heading and consequences" do
    rendered_component

    expect(page).to have_css("h2", text: "Complete this test run?")
    expect(page).to have_text("#{test_run.formatted_id} Sprint smoke")
    expect(page).to have_text("Statuses will be frozen")
    expect(page).to have_text("reopen the run later")
  end

  it "requires confirmation before completing" do
    rendered_component

    expect(page).to have_field(
      "I confirm that statuses will be frozen and written to each test case's history.",
      type: "checkbox"
    )
  end

  it "submits a POST to the complete path" do
    rendered_component

    expect(page).to have_css(
      "form[action='#{complete_project_test_management_test_run_path(project, test_run)}']"
    )
  end

  it "labels the confirm button Complete run rather than Delete permanently" do
    rendered_component

    expect(page).to have_button("Complete run")
    expect(page).to have_no_button("Delete permanently")
  end
end
