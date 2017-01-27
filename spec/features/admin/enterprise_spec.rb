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

describe 'Enterprise token', type: :feature do
  include Redmine::I18n

  let(:admin) { FactoryGirl.create(:admin) }
  let(:token_object) do
    token = OpenProject::Token.new
    token.subscriber = 'Foobar'
    token.mail = 'foo@example.org'
    token.starts_at = Date.today
    token.expires_at = nil

    token
  end

  let(:textarea) { find '#enterprise_token_encoded_token' }
  let(:submit_button) { find '#token-submit-button' }

  describe 'EnterpriseToken management' do
    before do
      login_as(admin)
      visit enterprise_path
    end

    it 'shows a teaser and token form without a token' do
      expect(page).to have_selector('.upsale-notification a', text: 'Order Enterprise Edition')
      expect(textarea.value).to be_empty

      textarea.set 'foobar'
      submit_button.click

      # Error output
      expect(page).to have_selector('.errorExplanation',
                                    text: "Enterprise support token can't be read. " \
                                          "Are you sure it is a support token?")
      expect(page).to have_selector('span.errorSpan #enterprise_token_encoded_token')

      # Keeps value
      expect(textarea.value).to eq('foobar')
    end

    context 'assuming valid input' do
      before do
        allow(OpenProject::Token).to receive(:import).and_return(token_object)
      end

      it 'allows token import flow', js: true do
        textarea.set 'foobar'
        submit_button.click

        expect(page).to have_selector('.flash.notice', text: I18n.t(:notice_successful_update))
        expect(page).to have_selector('.enterprise--active-token')

        expect(page.all('.attributes-key-value--key').map(&:text))
          .to eq ['Subscriber', 'Email', 'Valid since']
        expect(page.all('.attributes-key-value--value').map(&:text))
          .to eq ['Foobar', 'foo@example.org', format_date(Date.today)]

        expect(page).to have_selector('.button.icon-delete', text: I18n.t(:button_delete))

        # Expect section to be collapsed
        expect(page).to have_no_selector('#token_encoded_token', visible: true)

        expect(EnterpriseToken.current.encoded_token).to eq('foobar')

        # Replace token
        find('.collapsible-section--toggle-link').click
        textarea.set 'blabla'
        submit_button.click
        expect(page).to have_selector('.flash.notice', text: I18n.t(:notice_successful_update))

        # Assume next request
        RequestStore.clear!
        expect(EnterpriseToken.current.encoded_token).to eq('blabla')

        # Remove token
        find('.button.icon-delete', text: I18n.t(:button_delete)).click

        # Expect modal
        find('.confirm-form-submit--continue').click
        expect(textarea.value).to be_empty
        expect(page).to have_selector('.flash.notice', text: I18n.t(:notice_successful_delete))

        # Assume next request
        RequestStore.clear!
        expect(EnterpriseToken.current).to be_nil
      end
    end
  end
end
