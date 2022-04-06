#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

describe 'Files tab', js: true do
  let(:role) { create(:role, permissions: %i[view_work_packages edit_work_packages]) }
  let(:user) { create(:user, member_in_project: project, member_through_role: role) }
  let(:project) { create :project }
  let(:work_package) { create(:work_package, project: project) }
  let(:wp_page) { ::Pages::FullWorkPackage.new(work_package, project) }

  before do
    login_as(user)
  end

  describe 'navigation to new files tab from work package view' do
    before do
      wp_page.visit!
    end

    context 'if on work packages full view' do
      it 'must open files tab' do
        wp_page.switch_to_tab tab: 'activity'
        expect(page).not_to have_selector '.work-package--attachments--drop-box'

        files_link = wp_page.find('.work-packages--files-container .attributes-group--icon-indented-text a')
        files_link.click

        expect(page).to have_current_path project_work_package_path(project, work_package, 'files')
        expect(page).to have_selector '.work-package--attachments--drop-box'
      end
    end

    context 'if on work packages split view' do
      let(:wp_page) { ::Pages::SplitWorkPackage.new(work_package, project) }

      it 'must open files tab' do
        wp_page.switch_to_tab tab: 'overview'
        expect(page).not_to have_selector '.work-package--attachments--drop-box'

        files_link = wp_page.find('.work-packages--files-container .attributes-group--icon-indented-text a')
        files_link.click

        expect(page).to have_current_path project_work_packages_path(project) + "/details/#{work_package.id}/files"
        expect(page).to have_selector '.work-package--attachments--drop-box'
      end
    end
  end
end
