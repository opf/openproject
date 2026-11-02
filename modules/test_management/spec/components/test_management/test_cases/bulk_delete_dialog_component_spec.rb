# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::TestCases::BulkDeleteDialogComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:first) { create(:tm_test_case, project:, title: "First case") }
  shared_let(:second) { create(:tm_test_case, project:, title: "Second case") }

  subject(:rendered_component) do
    with_request_url "/projects/#{project.id}/test_management/test_cases" do
      render_inline(described_class.new(test_cases: [first, second], project:))
    end
  end

  it "renders the bulk heading and lists selected cases" do
    rendered_component

    expect(page).to have_css("h2", text: "Move these 2 test cases to Deleted?")
    expect(page).to have_text("##{first.id} First case")
    expect(page).to have_text("##{second.id} Second case")
    expect(page).to have_text("Deleted folder")
  end

  it "requires confirmation before delete" do
    rendered_component

    expect(page).to have_field(
      "I confirm that the selected test cases will be moved to the Deleted folder.",
      type: "checkbox"
    )
  end

  it "submits a DELETE with the selected ids" do
    rendered_component

    expect(page).to have_css("form[action='#{project_test_management_test_cases_bulk_path(project)}']")
    expect(page).to have_css("input[name='_method'][value='delete']", visible: :all)
    expect(page).to have_field("ids[]", with: first.id.to_s, type: :hidden)
    expect(page).to have_field("ids[]", with: second.id.to_s, type: :hidden)
  end

  it "labels the confirm button Move to Deleted rather than Delete permanently" do
    rendered_component

    expect(page).to have_button("Move to Deleted")
    expect(page).to have_no_button("Delete permanently")
  end

  it "summarizes instead of listing when many cases are selected" do
    cases = Array.new(described_class::LIST_LIMIT + 1) do |index|
      create(:tm_test_case, project:, title: "Case #{index}")
    end

    with_request_url "/projects/#{project.id}/test_management/test_cases" do
      render_inline(described_class.new(test_cases: cases, project:))
    end

    expect(page).to have_text("#{cases.size} test cases will be moved to Deleted.")
    expect(page).to have_no_text(cases.first.title)
  end
end
