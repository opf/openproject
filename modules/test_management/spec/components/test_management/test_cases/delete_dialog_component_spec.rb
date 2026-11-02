# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::TestCases::DeleteDialogComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:test_case) do
    create(:tm_test_case, project:, title: "Clear error messages")
  end

  subject(:rendered_component) do
    with_request_url "/projects/#{project.id}/test_management/test_cases/#{test_case.id}" do
      render_inline(described_class.new(test_case:, project:))
    end
  end

  it "renders the soft-delete heading and description" do
    rendered_component

    expect(page).to have_css("h2", text: "Move this test case to Deleted?")
    expect(page).to have_text("##{test_case.id} Clear error messages")
    expect(page).to have_text("Deleted folder")
    expect(page).to have_text("restore it later")
  end

  it "requires confirmation before delete" do
    rendered_component

    expect(page).to have_field(
      "I confirm that this test case will be moved to the Deleted folder.",
      type: "checkbox"
    )
  end

  it "submits a DELETE to the test case path" do
    rendered_component

    expect(page).to have_css("form[action='#{project_test_management_test_case_path(project, test_case)}']")
    expect(page).to have_css("input[name='_method'][value='delete']", visible: :all)
  end

  it "labels the confirm button Move to Deleted rather than Delete permanently" do
    rendered_component

    expect(page).to have_button("Move to Deleted")
    expect(page).to have_no_button("Delete permanently")
  end
end
