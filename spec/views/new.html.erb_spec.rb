
require 'spec_helper'

describe 'taskboard_card_configurations/new' do
  let(:config) { FactoryGirl.build(:taskboard_card_configuration) }

  before do
    assign(:config, config)
  end

  it 'shows new taskboard card configuration empty inputs' do
    render

    rendered.should have_css("input#taskboard_card_configuration_name")
    rendered.should have_css("input#taskboard_card_configuration_per_page")
    rendered.should have_css("input#taskboard_card_configuration_page_size")
    rendered.should have_css("select#taskboard_card_configuration_orientation")
    rendered.should have_css("textarea#taskboard_card_configuration_rows")
  end

end