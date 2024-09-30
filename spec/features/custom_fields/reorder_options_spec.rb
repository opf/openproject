require "spec_helper"
require "support/pages/custom_fields"

def get_possible_values(amount)
  (1..amount).to_a.map { |x| "PREFIX #{x}" }
end

def get_shuffled_possible_values(amount)
  get_possible_values(amount).shuffle(random: Random.new(2))
end

def get_possible_values_reordered(amount)
  get_possible_values(amount).sort
end

RSpec.describe "Reordering custom options of a list custom field", :js do
  let(:user) { create(:admin) }
  let(:cf_page) { Pages::CustomFields.new }

  let!(:custom_field) do
    create(
      :list_wp_custom_field,
      name: "Platform",
      possible_values: get_shuffled_possible_values(200)
    )
  end

  before do
    login_as(user)
  end

  it "reorders the items alphabetically when pressed" do
    expect(custom_field.custom_options.order(:position).pluck(:value))
      .to eq get_shuffled_possible_values(200)

    cf_page.visit!
    click_link custom_field.name

    click_link "Reorder values alphabetically"
    cf_page.accept_alert_dialog!
    expect_flash(message: I18n.t(:notice_successful_update))
    expect(custom_field.custom_options.order(:position).pluck(:value))
      .to eq get_possible_values_reordered(200)
  end
end
