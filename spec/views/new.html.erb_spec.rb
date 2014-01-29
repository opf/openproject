
require 'spec_helper'

describe 'export_card_configurations/new' do
  let(:config) { FactoryGirl.build(:export_card_configuration) }

  before do
    assign(:config, config)
  end

  it 'shows new export card configuration empty inputs' do
    render

    rendered.should have_css("input#export_card_configuration_name")
    rendered.should have_css("input#export_card_configuration_per_page")
    rendered.should have_css("input#export_card_configuration_page_size")
    rendered.should have_css("select#export_card_configuration_orientation")
    rendered.should have_css("textarea#export_card_configuration_rows")
  end

end