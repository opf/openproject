# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admin::Settings::WorkingDays::ConfirmDialogComponent, type: :component do
  let(:form_values) do
    {
      "working_days" => ["", "1", "2", "3"],
      "hours_per_day" => "8",
      "non_working_days_attributes" => {
        "12" => {
          "id" => "12",
          "_destroy" => "true"
        },
        "2026-06-10" => {
          "date" => "2026-06-10",
          "name" => "My holiday"
        }
      }
    }
  end

  it "renders the danger dialog with no button icon and keeps the confirmation texts" do
    render_inline(described_class.new(removed_non_working_days: ["June 10, 2026"]))

    expect(page).to have_css(".DangerDialog")
    expect(page).to have_css(".Button--danger", text: "Save and reschedule")
    expect(page).to have_no_css(".Button--danger svg")

    expect(page).to have_text("Change working days")
    expect(page).to have_css("h2", text: "Change the working days?")
    expect(page).to have_text("You will remove the following days from the non-working days list:")
    expect(page).to have_text("June 10, 2026")
    expect(page).to have_css("ul", text: "June 10, 2026")
  end

  it "submits the captured working days settings through the dialog form" do
    render_inline(described_class.new(form_values:))

    expect(page).to have_css('input[type="hidden"][name="_method"][value="patch"]', visible: :hidden)
    expect(page).to have_css('input[type="hidden"][name="settings[hours_per_day]"][value="8"]', visible: :hidden)
    expect(page).to have_css('input[type="hidden"][name="settings[working_days][]"][value="1"]', visible: :hidden)
    expect(page).to have_css('input[type="hidden"][name="settings[working_days][]"][value="2"]', visible: :hidden)
    expect(page).to have_css('input[type="hidden"][name="settings[working_days][]"][value="3"]', visible: :hidden)
  end

  it "submits captured non-working day changes through the dialog form" do
    render_inline(described_class.new(form_values:))

    expect(page).to have_css(
      'input[type="hidden"][name="settings[non_working_days_attributes][12][id]"][value="12"]',
      visible: :hidden
    )
    expect(page).to have_css(
      'input[type="hidden"][name="settings[non_working_days_attributes][12][_destroy]"][value="true"]',
      visible: :hidden
    )
    expect(page).to have_css(
      'input[type="hidden"][name="settings[non_working_days_attributes][2026-06-10][date]"][value="2026-06-10"]',
      visible: :hidden
    )
    expect(page).to have_css(
      'input[type="hidden"][name="settings[non_working_days_attributes][2026-06-10][name]"][value="My holiday"]',
      visible: :hidden
    )
  end
end
