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

RSpec.feature 'Work package pagination', js: true do

  let(:admin) { FactoryGirl.create(:admin) }
  let(:project) {
    FactoryGirl.create(:project, name: 'project1', identifier: 'project1')
  }

  shared_examples_for 'paginated work package list' do
    let!(:work_package_1) { FactoryGirl.create(:work_package, project: project) }
    let!(:work_package_2) { FactoryGirl.create(:work_package, project: project) }

    before do
      login_as(admin)
      allow(Setting).to receive(:per_page_options).and_return '1, 50, 100'

      visit path
      expect(current_path).to eq(expected_path)
    end

    scenario do
      expect(page).to have_content('Work packages')

      within('.work-packages-list-view--container') do
        expect(page).to     have_content(work_package_1.subject)
        expect(page).to_not have_content(work_package_2.subject)
      end

      within('.pagination--pages') do
        click_link '2'
      end

      within('.work-packages-list-view--container') do
        expect(page).to     have_content(work_package_2.subject)
        expect(page).to_not have_content(work_package_1.subject)
      end

      within('.pagination--options') do
        click_link '50'
      end

      within('.work-packages-list-view--container') do
        expect(page).to have_content(work_package_1.subject)
        expect(page).to have_content(work_package_2.subject)
      end
    end

  end

  context 'with project scope' do
    it_behaves_like 'paginated work package list' do
      let(:path) { project_work_packages_path(project) }
      let(:expected_path) { '/projects/project1/work_packages' }
    end
  end

  context 'globally' do
    it_behaves_like 'paginated work package list' do
      let(:path) { work_packages_path }
      let(:expected_path) { '/work_packages' }
    end
  end
end
