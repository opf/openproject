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
require 'features/work_packages/work_packages_page'

describe 'New work package', type: :feature do
  let(:user) { FactoryGirl.create(:admin) }
  let(:project) { FactoryGirl.create(:project) }
  let(:work_packages_page) { WorkPackagesPage.new(project) }

  before { allow(User).to receive(:current).and_return(user) }

  describe 'Datepicker', js: true do
    shared_examples_for 'first week day set' do |locale: :de|
      let(:datepicker_selector) { '#ui-datepicker-div table.ui-datepicker-calendar thead tr th:nth-of-type(2)' }

      before do
        allow(I18n).to receive(:locale).and_return(locale)
        expect(Setting).to receive(:start_of_week).and_return(day_of_week) unless day_of_week.nil?

        work_packages_page.visit_new

        # Fill in the date, as a simple click does not seem to trigger the datepicker here
        fill_in 'Start date', with: DateTime.now.strftime('%Y-%m-%d')
      end

      it { expect(page).to have_selector(datepicker_selector, text: day_acronym) }
    end

    context 'Monday' do
      it_behaves_like 'first week day set' do
        let(:day_of_week) { 1 }
        let(:day_acronym) { 'Mo' }
      end
    end

    context 'Sunday' do
      it_behaves_like 'first week day set' do
        let(:day_of_week) { 7 }
        let(:day_acronym) { 'So' }
      end
    end

    context 'Saturday' do
      it_behaves_like 'first week day set' do
        let(:day_of_week) { 6 }
        let(:day_acronym) { 'Sa' }
      end
    end

    context 'Language-specific' do
      it_behaves_like 'first week day set' do
        let(:day_of_week) { nil }
        let(:day_acronym) { 'Mo' }
      end

      it_behaves_like 'first week day set', locale: :en do
        let(:day_of_week) { nil  }
        let(:day_acronym) { 'Su' }
      end
    end
  end
end
