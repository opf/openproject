#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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

describe 'License', type: :feature do
  include Redmine::I18n

  let(:admin) { FactoryGirl.create(:admin) }
  let(:license_object) do
    license = OpenProject::License.new
    license.licensee = 'Foobar'
    license.mail = 'foo@example.org'
    license.starts_at = Date.today
    license.expires_at = nil

    license
  end

  let(:textarea) { find '#license_encoded_license' }
  let(:submit_button) { find '#license-submit-button' }

  describe 'License management' do
    before do
      login_as(admin)
      visit license_path
    end

    it 'shows a teaser and license form without a license' do
      expect(page).to have_selector('.upsale-notification a', text: 'Order license')
      expect(textarea.value).to be_empty

      textarea.set 'foobar'
      submit_button.click

      # Error output
      expect(page).to have_selector('.errorExplanation',
                                    text: "License data can't be read. Are you sure it is a license?")
      expect(page).to have_selector('span.errorSpan #license_encoded_license')

      # Keeps value
      expect(textarea.value).to eq('foobar')
    end

    context 'assuming valid input' do
      before do
        allow(OpenProject::License).to receive(:import).and_return(license_object)
      end

      it 'allows license import flow', js: true do
        textarea.set 'foobar'
        submit_button.click

        expect(page).to have_selector('.flash.notice', text: I18n.t(:notice_successful_update))
        expect(page).to have_selector('.license--active-license')

        expect(page.all('.attributes-key-value--key').map(&:text))
          .to eq ['Licensee', 'Email', 'Valid since']
        expect(page.all('.attributes-key-value--value').map(&:text))
          .to eq ['Foobar', 'foo@example.org', format_date(Date.today)]

        expect(page).to have_selector('.button.icon-delete', text: I18n.t(:button_delete))

        # Expect section to be collapsed
        expect(page).to have_no_selector('#license_encoded_license', visible: true)

        expect(License.current.encoded_license).to eq('foobar')

        # Replace license
        find('.collapsible-section--toggle-link').click
        textarea.set 'blabla'
        submit_button.click
        expect(page).to have_selector('.flash.notice', text: I18n.t(:notice_successful_update))

        expect(License.current.encoded_license).to eq('blabla')

        # Remove license
        find('.button.icon-delete', text: I18n.t(:button_delete)).click

        # Expect modal
        find('.confirm-form-submit--continue').click
        expect(textarea.value).to be_empty
        expect(page).to have_selector('.flash.notice', text: I18n.t(:notice_successful_delete))

        expect(License.current).to be_nil
      end
    end
  end
end
