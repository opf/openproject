
require 'spec_helper'

describe 'export_card_configurations/edit' do
  let(:config) { FactoryGirl.build(:export_card_configuration) }

  before do
    config.save
    assign(:config, config)
  end

  it 'shows edit export card configuration inputs' do
    render

    rendered.should have_field("Name", with: config.name)
    rendered.should have_field("Per page", with: config.per_page.to_s)
    rendered.should have_field("Page size", with: config.page_size)
    rendered.should have_field("Orientation", with: config.orientation)
    rendered.should have_field("Rows", with: config.rows)
  end

end