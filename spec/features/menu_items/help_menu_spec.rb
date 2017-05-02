#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

feature 'Help menu items' do
  let(:user) { FactoryGirl.create :admin }
  let(:help_item) { find('.menu-item--help') }

  before do
    login_as user
  end

  describe 'When force_help_link is not set', js: true do
    it 'renders a dropdown' do
      visit home_path

      help_item.click
      expect(page).to have_selector('.drop-down--help li',
                                    text: I18n.t('homescreen.links.user_guides'))
    end
  end

  describe 'When force_help_link is set' do
    let(:custom_url) { 'https://mycustomurl.example.org' }
    before do
      allow(OpenProject::Configuration).to receive(:force_help_link)
        .and_return custom_url
    end
    it 'renders a link' do
      visit home_path

      expect(help_item[:href]).to eq(custom_url)
      expect(page).to have_no_selector('.drop-down--help', visible: false)
    end
  end
end
