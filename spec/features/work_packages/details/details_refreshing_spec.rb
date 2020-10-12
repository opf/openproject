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
require 'features/work_packages/work_packages_page'

describe 'Work package table refreshing due to split view', js: true do
  let(:project) { FactoryBot.create :project_with_types }
  let!(:work_package) { FactoryBot.create :work_package, project: project }
  let(:wp_split) { ::Pages::SplitWorkPackage.new work_package }
  let(:wp_table) { ::Pages::WorkPackagesTable.new project }
  let(:user) { FactoryBot.create :admin }

  before do
    login_as(user)
    wp_split.visit!
  end

  it 'toggles the watch state' do
    wp_split.ensure_page_loaded
    wp_split.edit_field(:subject).expect_text work_package.subject

    wp_table.expect_work_package_listed work_package
    page.within wp_table.row(work_package) do
      expect(page).to have_selector('.wp-table--drag-and-drop-handle.icon-drag-handle', visible: :all)
    end
  end
end
