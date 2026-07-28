# frozen_string_literal: true

require "spec_helper"

# After an administrator changes a user's attributes out-of-band (e.g. their department,
# or the "Job title" custom field), the account page must not keep showing the old values.
# The examples below cover each way of returning to the page.
RSpec.describe "My account is never served stale after an out-of-band change", :js do
  shared_let(:admin) { create(:admin) }
  shared_let(:section) { create(:user_custom_field_section, name: "Professional info") }
  shared_let(:job_title) { create(:user_custom_field, :string, name: "Job title", user_custom_field_section: section) }
  shared_let(:alpha) { create(:department, name: "Alpha department", members: [admin]) }
  shared_let(:beta) { create(:department, name: "Beta department") }

  before do
    section.update!(attribute_order: ["department", job_title.column_name])
    admin.update!(custom_field_values: { job_title.id => "Old title" })
    login_as admin
    visit my_account_path
  end

  # Confirms the page rendered the current values, then has an administrator change the
  # department and job title out-of-band so that any browser/Turbo cache now holds stale data.
  def change_department_and_job_title_out_of_band
    expect(page).to have_select("user[department_id]", disabled: true, selected: "Alpha department")
    expect(page).to have_field("Job title", with: "Old title")

    Departments::AddUserService.new(beta, user: admin)
                               .call(user_id: admin.id, remove_from_previous_department: true)
    admin.update!(custom_field_values: { job_title.id => "New title" })
  end

  def expect_fresh_account
    expect(page).to have_select("user[department_id]", disabled: true, selected: "Beta department")
    expect(page).to have_field("Job title", with: "New title")
  end

  # Fixed by the `turbo-cache-control: no-cache` meta: a restoration visit would
  # otherwise re-render Turbo's cached snapshot.
  it "is fresh after navigating away and back through browser history" do
    change_department_and_job_title_out_of_band

    click_on "Notification and email"
    expect(page).to have_current_path(my_notifications_path, wait: 10, ignore_query: true)

    page.go_back

    expect_fresh_account
  end
end
