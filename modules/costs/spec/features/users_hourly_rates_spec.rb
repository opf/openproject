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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe 'hourly rates on user edit', type: :feature, js: true do
  let(:user) { FactoryBot.create :admin }

  def view_rates
    visit edit_user_path(user, tab: 'rates')
  end

  before do
    allow(User).to receive(:current).and_return user
  end

  context 'with no rates' do
    before do
      view_rates
    end

    it 'shows no data message' do
      expect(page).to have_text I18n.t('no_results_title_text')
    end
  end

  context 'with rates' do
    let!(:rate) { FactoryBot.create(:default_hourly_rate, user: user) }

    before do
      view_rates
    end

    it 'shows the rates' do
      expect(page).to have_text 'Current rate'.upcase
    end

    describe 'deleting all rates' do
      before do
        click_link 'Update'         # go to update view for rates
        find('.icon-delete').click  # delete last existing rate
        click_on 'Save'             # save change
      end

      # regression test: clicking save used to result in a error
      it 'leads back to the now empty rate overview' do
        expect(page).to have_text /rate history/i
        expect(page).to have_text I18n.t('no_results_title_text')

        expect(page).not_to have_text 'Current rate'
      end
    end
  end
end
