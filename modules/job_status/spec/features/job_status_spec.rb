#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe 'Job status', type: :feature, js: true do
  shared_let(:admin) { create :admin }

  before do
    login_as admin
  end

  it 'renders a descriptive error in case of 404' do
    visit '/job_statuses/something-that-does-not-exist'

    expect(page).to have_selector('.icon-big.icon-help', wait: 10)
    expect(page).to have_content I18n.t('js.job_status.generic_messages.not_found')
  end

  describe 'with a status that has an additional errors payload' do
    let!(:status) { create(:delayed_job_status, user: admin) }

    before do
      status.update! payload: { errors: ['Some error', 'Another error'] }
    end

    it 'will show a list of these errors' do
      visit "/job_statuses/#{status.job_id}"

      expect(page).to have_selector('.job-status--modal-additional-errors', text: 'Some errors have occurred', wait: 10)
      expect(page).to have_selector('ul li', text: 'Some error')
      expect(page).to have_selector('ul li', text: 'Another error')
    end
  end

  describe 'with a status with error and redirect' do
    let!(:status) { create(:delayed_job_status, user: admin) }

    before do
      status.update! payload: { redirect: home_url, errors: ['Some error'] }
    end

    it 'will not automatically redirect' do
      visit "/job_statuses/#{status.job_id}"

      expect(page).to have_selector('.job-status--modal-additional-errors', text: 'Some errors have occurred', wait: 10)
      expect(page).to have_selector('ul li', text: 'Some error')
      expect(page).to have_selector("a[href='#{home_url}']", text: 'Please click here to continue')
    end
  end
end
