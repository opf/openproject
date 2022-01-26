require 'spec_helper'
require 'support/pages/custom_fields'

describe 'Reordering custom options of a list custom field', js: true do
  let(:user) { create :admin }
  let(:cf_page) { Pages::CustomFields.new }

  let!(:custom_field) do
    create(
      :list_wp_custom_field,
      name: "Platform",
      possible_values: %w[Playstation Xbox Nintendo PC Switch Mobile Dreamcast]
    )
  end

  before do
    login_as(user)
  end

  it 'reorders the items alphabetically when pressed' do
    expect(custom_field.custom_options.order(:position).pluck(:value))
      .to eq %w[Playstation Xbox Nintendo PC Switch Mobile Dreamcast]

    cf_page.visit!
    click_link custom_field.name

    click_link 'Reorder values alphabetically'
    cf_page.accept_alert_dialog!
    expect(page).to have_selector('.flash.notice', text: I18n.t(:notice_successful_update))
    expect(custom_field.custom_options.order(:position).pluck(:value))
      .to eq %w[Dreamcast Mobile Nintendo PC Playstation Switch Xbox]
  end
end
