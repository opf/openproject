#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++
require 'spec_helper'

describe "export card configurations Admin", type: :feature, js: true do
  let(:user) { FactoryBot.create :admin }

  let!(:config1) { FactoryBot.create :export_card_configuration }
  let!(:config_default) { FactoryBot.create :default_export_card_configuration }
  let!(:config_active) { FactoryBot.create :active_export_card_configuration }

  before do
    login_as user
    visit pdf_export_export_card_configurations_path
  end

  it 'can manage export card configurations' do
    # INDEX
    expect(page).to have_text 'Config 1'
    expect(page).to have_text 'Default '
    expect(page).to have_text 'Config active'

    # CREATE
    click_on 'New Export Card Config'
    fill_in 'export_card_configuration_name', with: 'New config'
    fill_in 'export_card_configuration_per_page', with: '5'
    select 'landscape', from: 'export_card_configuration_orientation'
    valid_yaml = "groups:\n  rows:\n    row1:\n      columns:\n        id:\n          has_label: false"
    fill_in 'export_card_configuration_rows', with: valid_yaml
    click_on 'Create'
    expect(page).to have_text 'Successful creation.'

    # EDIT
    page.first('a', text: 'Config 1').click
    fill_in 'export_card_configuration_name', with: 'New name'
    fill_in 'export_card_configuration_per_page', with: '5'
    select 'portrait', from: 'export_card_configuration_orientation'
    fill_in 'export_card_configuration_rows', with: valid_yaml
    click_on 'Save'
    expect(page).to have_text 'Successful update.'

    expect(config1.reload.name).to eq 'New name'
    expect(config1.reload).to be_portrait

    # DEACTIVATE
    page.first('a', text: 'De-activate').click
    expect(page).to have_text 'Config succesfully de-activated'

    # ACTIVATE
    page.first('a', text: 'Activate').click
    expect(page).to have_text 'Config succesfully activated'
  end
end