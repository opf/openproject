
require 'spec_helper'

describe 'taskboard_card_configurations/edit' do
  let(:config) { FactoryGirl.build(:taskboard_card_configuration) }

  before do
    config.save
    assign(:config, config)
  end

  it 'shows edit taskboard card configuration inputs' do
    render

    rendered.should have_selector("form") do |f|
      f.should have_selector("input", value: config.identifier)
      f.should have_selector("input", value: config.name)
      f.should have_selector("input", value: config.rows)
      f.should have_selector("input", value: config.per_page)
      f.should have_selector("input", value: config.page_size)
      f.should have_selector("input", value: config.orientation)
    end
  end

end