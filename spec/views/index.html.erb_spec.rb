
require 'spec_helper'

describe 'taskboard_card_configurations/index' do
  let(:config1) { FactoryGirl.build(:taskboard_card_configuration, name: "Config 1") }
  let(:config2) { FactoryGirl.build(:taskboard_card_configuration, name: "Config 2") }

  before do
    config1.save
    config2.save
    assign(:configs, [config1, config2])
  end

  it 'shows taskboard card configurations' do
    render

    rendered.should have_selector("a", text: config1.name)
    rendered.should have_selector("a", text: config1.name)
  end

end