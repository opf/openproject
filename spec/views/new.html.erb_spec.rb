
require 'spec_helper'

describe 'taskboard_card_configurations/new' do
  let(:config) { FactoryGirl.build(:taskboard_card_configuration) }

  before do
    assign(:config, config)
  end

  it 'shows new taskboard card configuration empty inputs' do
    render

    rendered.should have_selector("form") do |f|
      f.should have_selector("input", value: "")
      f.should have_selector("input", value: "")
      f.should have_selector("input", value: "")
      f.should have_selector("input", value: "")
      f.should have_selector("input", value: "")
      f.should have_selector("input", value: "")
    end
  end

end