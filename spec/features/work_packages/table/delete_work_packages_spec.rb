# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
# ++

require 'spec_helper'

describe 'Delete work package', js: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:context_menu) { Components::WorkPackages::ContextMenu.new }
  let(:destroy_modal) { Components::WorkPackages::DestroyModal.new }

  before do
    login_as(user)
  end

  shared_examples 'close split view' do
    describe 'when deleting a work package that is opened in the split view' do
      before do
        work_package

        split_view.visit!
        split_view.ensure_page_loaded

        context_menu.open_for(work_package)
        context_menu.choose('Delete')

        destroy_modal.expect_listed(work_package)
        destroy_modal.confirm_deletion

        loading_indicator_saveguard
      end

      it 'should close the split view' do
        split_view.expect_closed
        wp_table.expect_current_path
      end
    end
  end

  describe 'deleting multiple work packages in the table' do
    let!(:wp1) { FactoryBot.create(:work_package) }
    let!(:wp2) { FactoryBot.create(:work_package) }
    let!(:wp_child) { FactoryBot.create(:work_package, parent: wp1) }

    let(:wp_table) { Pages::WorkPackagesTable.new }

    it 'shows deletion for all selected work packages' do
      wp_table.visit!

      wp_table.expect_work_package_listed wp1, wp2, wp_child
      find('body').send_keys [:control, 'a']

      context_menu.open_for(wp1)
      context_menu.choose('Bulk delete')

      destroy_modal.expect_listed(wp1, wp2, wp_child)
      destroy_modal.cancel_deletion
      wp_table.expect_work_package_listed wp1, wp2, wp_child

      context_menu.open_for(wp1)
      context_menu.choose('Bulk delete')
      destroy_modal.confirm_children_deletion
      destroy_modal.confirm_deletion

      loading_indicator_saveguard
      wp_table.expect_no_work_package_listed
    end
  end

  describe 'when deleting it outside a project context' do
    let(:work_package) { FactoryBot.create(:work_package) }
    let(:split_view) { Pages::SplitWorkPackage.new(work_package) }
    let(:wp_table) { Pages::WorkPackagesTable.new }

    it_behaves_like 'close split view'
  end

  describe 'when deleting it within a project context' do
    let(:project) { FactoryBot.create(:project) }
    let(:work_package) { FactoryBot.create(:work_package, project:project) }
    let(:split_view) { Pages::SplitWorkPackage.new(work_package, project.identifier) }
    let(:wp_table) { Pages::WorkPackagesTable.new(project.identifier) }

    it_behaves_like 'close split view'
  end
end
